//
//  ViewController.swift
//  ContactDetailFetch
//
//  Created by Priya Gnaneshwaran on 30/06/25.
//

import UIKit
import Contacts
import ContactsUI

struct Person {
    let name: String
    let id: String
    let source: CNContact
}

class ViewController: UIViewController, CNContactPickerDelegate {
    
    var models = [Person]()
    let store = CNContactStore()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }

    @IBAction func actionAddContacts(_ sender: UIBarButtonItem) {
        let nav = CNContactPickerViewController()
        nav.delegate = self
        self.present(nav, animated: true)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        print("\n\n \(contact)")
        guard models.contains(where: {$0.id == contact.identifier}) == false else { return }
        let name = contact.givenName + " " + contact.familyName
        let identifier = contact.identifier
        let model = Person(name: name, id: identifier, source: contact)
        models.append(model)
        self.tableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = models[indexPath.row].name
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = models[indexPath.row].source
        let nav = CNContactViewController(for: contact)
        nav.allowsEditing = true
        nav.contactStore = CNContactStore()
        self.present(nav, animated: true)
    }
}
