//
//  TaskController.swift
//  Tasks
//
//  Created by Breena Greek on 4/27/20.
//  Copyright © 2020 Andrew R Madsen. All rights reserved.
//

import Foundation
import CoreData

enum NetworkError: Error {
    case noIdentifier
    case otherError
    case noData
    case noDecode
    case noEncode
    case noRep
}

class TaskController {
    
    //    func put(task: Task, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
    //        Instead do below
    //    }
    
    typealias CompletionHandler = (Result<Bool, NetworkError>) -> Void
    
    let baseURL = URL(string: "https://tasks-3f211.firebaseio.com/")!
    
    func put(task: Task, completion: @escaping CompletionHandler) {
        
        // Check to make sure an ID exists, otherwise we cannot put task to a unique place in firebase
        guard let identifier = task.identifier else {
            completion(.failure(.noIdentifier))
            return
        }
        
        let requestURL = baseURL.appendingPathComponent(identifier.uuidString).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        // Turn the task into a task representation, then TR into JSon.
        
        do {
            guard let taskRepresentation = task.taskRepresentation else {
                completion(.failure(.noRep))
                return
            }
            
            request.httpBody = try JSONEncoder().encode(taskRepresentation)
        } catch {
            NSLog("Error encoding task \(task): \(error)")
            completion(.failure(.noEncode))
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("Error putting tassk to server: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
    
    func fetchTasksFromServer(completion: @escaping CompletionHandler = { _ in }) {
        
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error fetching tasks: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.otherError))
                }
                return
            }
            
            guard let data = data else {
                NSLog("Error: No data return from data task")
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            // Pull the Json out of the data, and turn it into Task Representation.
            do {
                let taskRepresentations = try JSONDecoder().decode([String: TaskRepresentation].self, from: data).map({ $0.value })
                
                // Figure out which task representations dont exist in core data so we can add them, and figure out which ones have changed.
                try self.updateTasks(with: taskRepresentations)
                DispatchQueue.main.async {
                    completion(.success(true))
                }
            } catch {
                NSLog("Error decoding task representation: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.noDecode))
                }
            }
        }
    }
    
    func updateTasks(with representations: [TaskRepresentation]) throws {
        
        let identifiersToFetch = representations.compactMap({ UUID(uuidString: $0.identifier) })
        
        let representationsByID = Dictionary(uniqueKeysWithValues:
            zip(identifiersToFetch, representations)
        )
        
        // Make a copy of the representations by ID for later use
        var tasksToCreate = representationsByID
        
        // Ask CoreData to find any tasks with these identifiers
        // if identifiersToFetch.contains(someTaskincoreData)
        let predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = predicate
        
        let context = CoreDataStack.shared.mainContext
        
        do {
            // This will only fetch request that match the criteria in our predicate
            let existingTasks = try context.fetch(fetchRequest)
            
            // Lets update the tasks that already exist in Core Data
            for task in existingTasks {
                guard let id = task.identifier,
                    let representation = representationsByID[id] else { continue }
                
                task.name = representation.name
                task.notes = representation.notes
                task.complete = representation.complete
                task.priority = representation.priority
                
                // If we updated the task, tht means we dont need to make a copy of it, it already exists in Core Data, so remove it from te task we still need to create.
                tasksToCreate.removeValue(forKey: id)
            }
            
            // Add the tasks that dont exist
            for representation in tasksToCreate.values {
                Task(taskRepresentation: representation, context: context)
            }
            
        } catch {
            NSLog("Error fetching tasks for UUID: \(error)")
        }
        
        try self.saveToPersistentStore()
    }
    
    func saveToPersistentStore() throws {
        let moc = CoreDataStack.shared.mainContext
        try moc.save()
    }
}
