//
//  TaskDetailViewController.swift
//  Tasks
//
//  Created by Andrew R Madsen on 8/11/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class TaskDetailViewController: UIViewController {
    
    // MARK: Properties
    
    var task: Task?
    var wasEdited = false
    var taskController: TaskController?
    
    // MARK: - Outlets

    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var priorityControl: UISegmentedControl!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet var notesTextView: UITextView!

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = editButtonItem
        
        updateViews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if wasEdited {
            guard let name = nameTextField.text,
                !name.isEmpty,
                let task = task else {
                return
            }
            let notes = notesTextView.text
            task.name = name
            task.notes = notes
            let priorityIndex = priorityControl.selectedSegmentIndex
            task.priority = TaskPriority.allCases[priorityIndex].rawValue
            taskController?.put(task: task, completion: { _ in })
            do {
                try CoreDataStack.shared.mainContext.save()
            } catch {
                NSLog("Error saving managed object context: \(error)")
            }
        }
    }
    
    // MARK: - Editing
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing { wasEdited = true }
        
        nameTextField.isUserInteractionEnabled = editing
        notesTextView.isUserInteractionEnabled = editing
        priorityControl.isUserInteractionEnabled = editing
        navigationItem.hidesBackButton = editing
    }
    
    // MARK: - Actions
    
    @IBAction func toggleComplete(_ sender: UIButton) {
        wasEdited = true
        task?.complete.toggle()
        sender.setImage((task?.complete ?? false) ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"),for: .normal)
    }
 
    @objc func save() {
        guard let name = nameTextField.text, !name.isEmpty else {
            return
        }
        let priorityIndex = priorityControl.selectedSegmentIndex
        let priority = TaskPriority.allCases[priorityIndex]
        let notes = notesTextView.text
        
        Task(name: name, notes: notes, priority: priority)
        
        do {
            try CoreDataStack.shared.mainContext.save()
            navigationController?.dismiss(animated: true, completion: nil)
        } catch {
            NSLog("Error saving managed object context: \(error)")
        }
    }
    
    // MARK: - Private
    
    private func updateViews() {
        nameTextField.text = task?.name
        nameTextField.isUserInteractionEnabled = isEditing
        
        notesTextView.text = task?.notes
        notesTextView.isUserInteractionEnabled = isEditing
        
        completeButton.setImage((task?.complete ?? false) ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"),for: .normal)
        
        let priority: TaskPriority
        if let taskPriority = task?.priority {
            priority = TaskPriority(rawValue: taskPriority)!
        } else {
            priority = .normal
        }
        priorityControl.selectedSegmentIndex = TaskPriority.allCases.firstIndex(of: priority) ?? 1
        priorityControl.isUserInteractionEnabled = isEditing
    }
}
