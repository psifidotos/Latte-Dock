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

#ifndef EDGEPRESSURE_H
#define EDGEPRESSURE_H

#include "../liblattedock/dock.h"

#include <QObject>

namespace Latte {

class DockView;

class EdgePressure : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(EdgePressure)

    Q_PROPERTY(Latte::Dock::PressureThreshold threshold READ threshold WRITE setThreshold NOTIFY thresholdChanged)

public:
    EdgePressure(DockView* view, QObject* parent = nullptr);
    virtual ~EdgePressure();

    void update();
    void disable();

    bool enabled() const;

    Latte::Dock::PressureThreshold threshold() const;
    void setThreshold(Latte::Dock::PressureThreshold value);

signals:
    void thresholdReached(QPrivateSignal);
    void thresholdChanged();

private:
    class Private;
    Private* const d;
};

}

#endif // EDGEPRESSURE_H

