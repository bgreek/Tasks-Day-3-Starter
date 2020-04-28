//
//  TaskRepresentation.swift
//  Tasks
//
//  Created by Breena Greek on 4/27/20.
//  Copyright © 2020 Andrew R Madsen. All rights reserved.
//

import Foundation

// The bridge between our NSManagedObjectTask and the Task in Json from from teh server.

struct TaskRepresentation: Codable {
    var complete: Bool
    var identifier: String
    var name: String
    var notes: String?
    var priority: String
}
