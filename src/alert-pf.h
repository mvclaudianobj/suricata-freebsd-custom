/* Copyright (C) 2007-2023 Open Information Security Foundation
 *
 * You can copy, redistribute or modify this Program under the terms of
 * the GNU General Public License version 2 as published by the Free
 * Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * version 2 along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301, USA.
 *
 * Portions of this module are based on previous works of the following:
 *
 * Copyright (c) 2024  Bill Meeks
 * Copyright (c) 2012  Ermal Luci
 * Copyright (c) 2006  Antonio Benojar <zz.stalker@gmail.com>
 * Copyright (c) 2005  Antonio Benojar <zz.stalker@gmail.com>
 * Copyright (c) 2003, 2004 Armin Wolfermann:
 *
 * All rights reserved.
 */

/**
 * \file
 *
 * \author Bill Meeks <billmeeks8@gmail.com>
 */

#ifndef __ALERT_PF_H__
#define __ALERT_PF_H__

void AlertPfRegister (void);
OutputInitResult AlertPfInitCtx(ConfNode *);
int AlertPfCondition(ThreadVars *tv, void *thread_data, const Packet *p);
int AlertPf(ThreadVars *, void *, const Packet *);
TmEcode AlertPfThreadInit(ThreadVars *, const void *, void **);
TmEcode AlertPfThreadDeinit(ThreadVars *, void *);
void AlertPfExitPrintStats(ThreadVars *, void *);
void *AlertPfMonitorIfaceChanges(void *);

#endif /* __ALERT_PF_H__ */