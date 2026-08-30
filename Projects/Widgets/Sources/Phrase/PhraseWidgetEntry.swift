//
//  PhraseWidgetEntry.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import WidgetKit

import Domain

struct PhraseWidgetEntry: TimelineEntry {
    let date: Date
    let phrase: PhraseWidgetSnapshotItem?
}
