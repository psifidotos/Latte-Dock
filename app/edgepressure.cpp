/*
*  Copyright 2016  Smith AR <audoban@openmailbox.org>
*                  Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of Latte-Dock
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "config-latte.h"
#include "../liblattedock/extras.h"
#include "edgepressure.h"
#include "dockview.h"
#include "plasmaquick/containmentview.h"
#include "screenpool.h"

#include <cmath>
#include <algorithm>

#include <QDebug>
#include <QAbstractNativeEventFilter>

#include <KWindowSystem>
#include <Plasma>

#if HAVE_X11
    #include <X11/Xlib.h>
    #include <X11/extensions/XInput2.h>
    #include <xcb/xcb.h>
    #include <xcb/xfixes.h>
    #include <xcb/xinput.h>
    #include <xcb/xcb_event.h>
    #include <xcb/xproto.h>
    #include <QX11Info>
#endif

struct _BarrierSupport {
    _BarrierSupport();
    static bool enabled;
};

bool _BarrierSupport::enabled{false};

class Latte::EdgePressure::Private : QAbstractNativeEventFilter
{
public:
    Private(Latte::DockView* view, Latte::EdgePressure* q);
    virtual ~Private();

#if HAVE_X11
    void initBarrierX11();
    void updateBarrierX11();
    inline void processBarrierX11(xcb_input_barrier_hit_event_t *event);
    void deleteBarrierX11();

    xcb_connection_t *connection {nullptr};
    xcb_xfixes_barrier_t barrier {0};
#endif

    DockView *view;
    EdgePressure *q;
    std::unique_ptr<_BarrierSupport> BarrierSupport;
    uint pressureThreshold{Dock::ThresholdMedium};
    uint pressure{0};

protected:
    bool nativeEventFilter(const QByteArray & eventType, void * message, long * result) override;
};


//! BEGIN: EdgePressure::Private
_BarrierSupport::_BarrierSupport()
{
    if (enabled)
        return;

#if HAVE_X11
    auto c = QX11Info::connection();

    auto cookie = xcb_query_extension(c, sizeof(XFIXES_NAME), XFIXES_NAME);
    xcb_generic_error_t *error{nullptr};

    std::unique_ptr<xcb_query_extension_reply_t, pod_deleter> reply(xcb_query_extension_reply(c, cookie, &error));

    if (error) {
        qDebug() << "Barriers support disabled";
        free(error);
        return;
    }

    qDebug() << "Barriers support enabled";

    enabled = true;

    XIEventMask mask;
    unsigned char mask_bits[XIMaskLen (XI_LASTEVENT)] = { 0 };

    XISetMask (mask_bits, XI_BarrierHit);
    XISetMask (mask_bits, XI_BarrierLeave);
    mask.deviceid = XIAllMasterDevices;
    mask.mask = mask_bits;
    mask.mask_len = sizeof (mask_bits);
    XISelectEvents(QX11Info::display(), QX11Info::appRootWindow(), &mask, 1);
#endif
}

Latte::EdgePressure::Private::Private(Latte::DockView* view, Latte::EdgePressure *q)
    : view(view), q(q)
{
}

Latte::EdgePressure::Private::~Private()
{
    qGuiApp->removeNativeEventFilter(this);
}

#if HAVE_X11
void Latte::EdgePressure::Private::initBarrierX11()
{
    if (!connection)
        connection = QX11Info::connection();

    if (!BarrierSupport)
        BarrierSupport = std::make_unique<_BarrierSupport>();
}

void Latte::EdgePressure::Private::updateBarrierX11()
{
    if (!BarrierSupport)
        initBarrierX11();

    if (!BarrierSupport->enabled)
        return;

    if (barrier != 0)
        deleteBarrierX11();

    QRect rect{view->absGeometry()};
    if (rect.left() < rect.right() || rect.top() < rect.bottom()) {
        qDebug() << "the geometry is valid, winId" << view->winId();
    } else {
        qDebug() << "the geometry is invalid, winId" << view->winId();
    }

    Plasma::Types::Location location{view->location()};
    xcb_void_cookie_t cookie;
    barrier = xcb_generate_id(connection);

    switch(location) {
        case Plasma::Types::TopEdge:
            cookie = xcb_xfixes_create_pointer_barrier_checked(connection
            , barrier, QX11Info::appRootWindow()
            , rect.left(), rect.top(), rect.right(), rect.top()
            , XCB_XFIXES_BARRIER_DIRECTIONS_POSITIVE_Y
            , 0, nullptr);

            break;
        case Plasma::Types::BottomEdge:
            cookie = xcb_xfixes_create_pointer_barrier_checked(connection
            , barrier, QX11Info::appRootWindow()
            , rect.left(), rect.bottom() + 2, rect.right(), rect.bottom() + 2
            , XCB_XFIXES_BARRIER_DIRECTIONS_NEGATIVE_Y
            , 0, nullptr);

            break;
        case Plasma::Types::LeftEdge:
            cookie = xcb_xfixes_create_pointer_barrier_checked(connection
            , barrier, QX11Info::appRootWindow()
            , rect.left(), rect.top(), rect.left(), rect.bottom()
            , XCB_XFIXES_BARRIER_DIRECTIONS_POSITIVE_X
            , 0, nullptr);

            break;
        case Plasma::Types::RightEdge:
            cookie = xcb_xfixes_create_pointer_barrier_checked(connection
            , barrier, QX11Info::appRootWindow()
            , rect.right() + 2, rect.top(), rect.right() + 2, rect.bottom()
            , XCB_XFIXES_BARRIER_DIRECTIONS_NEGATIVE_X
            , 0, nullptr);
            break;

        default:
            return;
    }

    std::unique_ptr<xcb_generic_error_t, pod_deleter> error{xcb_request_check(connection, cookie)};
    if (error) {
        qDebug() << "the barrier can't be created, winId" << view->winId() << "error code", error->error_code;
    } else {
        qDebug() << "the barrier has been updated, winId" << view->winId() << rect;
    }

    qGuiApp->installNativeEventFilter(this);
}

inline void Latte::EdgePressure::Private::processBarrierX11(xcb_input_barrier_hit_event_t *event)
{
    uint slide{0};
    uint distance{0};

    if (view->formFactor() == Plasma::Types::Vertical) {
        distance = std::abs(event->dx.integral);
        slide = std::abs(event->dy.integral);
    } else {
        distance = std::abs(event->dy.integral);
        slide = std::abs(event->dx.integral);
    }

    if (slide < distance) {
        pressure += std::min(10u, distance);
        qDebug() << "pressure:" << pressure;
    }

    if (pressure >= pressureThreshold) {
        pressure = 0;
        qDebug() << "pressure threshold reached:" << pressureThreshold;

        emit q->thresholdReached({});
    }

    XIBarrierReleasePointer (QX11Info::display(), event->deviceid, barrier, event->eventid);
}

void Latte::EdgePressure::Private::deleteBarrierX11()
{
    qGuiApp->removeNativeEventFilter(this);

    if (barrier == 0)
        return;

    auto cookie = xcb_xfixes_delete_pointer_barrier_checked(connection, barrier);
    std::unique_ptr<xcb_generic_error_t, pod_deleter> error
    {xcb_request_check(connection, cookie)};

    if (error) {
        qDebug() << "the barrier can't be deleted, winId:" << view->winId();
    } else {
        qDebug() << "the barrier has been deleted, winId:" << view->winId();
    }
    barrier = 0;
}
#endif

bool Latte::EdgePressure::Private::nativeEventFilter(const QByteArray& eventType, void* message, long* result)
{
    Q_UNUSED(result)

#if HAVE_X11
    if (eventType != "xcb_generic_event_t")
        return false;

    auto ev = static_cast<xcb_generic_event_t *>(message);

    auto responseType = XCB_EVENT_RESPONSE_TYPE(ev);

    if (responseType == XCB_GE_GENERIC) {
        auto gev = static_cast<xcb_ge_generic_event_t *>(message);

        switch (gev->event_type) {
            case XCB_INPUT_BARRIER_HIT: {
                auto hit = static_cast<xcb_input_barrier_hit_event_t *>(message);

                if (hit->barrier == barrier) {
                    processBarrierX11(hit);
                    return true;
                }
            }
            return false;

            case XCB_INPUT_BARRIER_LEAVE: {
                auto leave = static_cast<xcb_input_barrier_leave_event_t *>(message);

                if (leave->barrier == barrier) {
                    pressure = 0;
                    return true;
                }
            }
            return false;
        }
    }
#endif

    return false;
}
//! END: EdgePressure::Private

//! BEGIN: EdgePressure
Latte::EdgePressure::EdgePressure(DockView *view, QObject* parent)
    : QObject(parent), d(new Private(view, this))
{
}

Latte::EdgePressure::~EdgePressure()
{
    delete d;
}

bool Latte::EdgePressure::enabled() const
{
    if (KWindowSystem::isPlatformWayland()) {
        //! NOT IMPLEMENTED
    } else {
#if HAVE_X11
        return d->barrier > 0;
#endif
    }

    return false;
}

Latte::Dock::PressureThreshold Latte::EdgePressure::threshold() const
{
    return static_cast<Dock::PressureThreshold>(d->pressureThreshold);
}

void Latte::EdgePressure::setThreshold(Latte::Dock::PressureThreshold value)
{
    if (static_cast<uint>(value) == d->pressureThreshold)
        return;

    d->pressureThreshold = value;
    emit thresholdChanged();
}

void Latte::EdgePressure::update()
{
    if (KWindowSystem::isPlatformWayland()) {
        //! NOT IMPLEMENTED
    } else {
#if HAVE_X11
        d->updateBarrierX11();
#endif
    }
}

void Latte::EdgePressure::disable()
{
    if (KWindowSystem::isPlatformWayland()) {
        //! NOT IMPLEMENTED
    } else {
#if HAVE_X11
        d->deleteBarrierX11();
#endif
    }
}
//! END: EdgePressure
