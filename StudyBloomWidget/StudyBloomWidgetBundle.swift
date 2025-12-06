//
//  StudyBloomWidgetBundle.swift
//  StudyBloomWidget
//
//  Created by Dragos Dima on 06.12.2025.
//

import WidgetKit
import SwiftUI

@main
struct StudyBloomWidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyTimerWidget()
        StudyBloomWidgetControl()
        StudyTimerWidgetLive()
    }
}
