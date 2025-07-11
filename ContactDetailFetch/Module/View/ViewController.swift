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
    
    @IBOutlet weak var tableView: UITableView!
    
    let store = CNContactStore()
    var models: [Person] = []
    
    // Sectioned contacts
    var contactDict: [String: [Person]] = [:]
    var sectionTitles: [String] = []
    
    // Filtered results
    var filteredDict: [String: [Person]] = [:]
    var filteredSectionTitles: [String] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addContactTapped))
        
        setupSearch()
        requestAccessAndFetchContacts()
    }
    
    @objc func addContactTapped() {
        let newContact = CNMutableContact()
        let contactVC = CNContactViewController(forNewContact: newContact)
        contactVC.contactStore = store
        contactVC.delegate = self
        let nav = UINavigationController(rootViewController: contactVC)
        present(nav, animated: true)
    }
    
    func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    func requestAccessAndFetchContacts() {
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                self.fetchAllContacts()
            }
        }
    }
    
    func fetchAllContacts() {
        DispatchQueue.global(qos: .userInitiated).async {
            let keys: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactIdentifierKey as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keys)
            var people: [Person] = []
            
            do {
                try self.store.enumerateContacts(with: request) { contact, _ in
                    let name = (contact.givenName + " " + contact.familyName).trimmingCharacters(in: .whitespaces)
                    let person = Person(name: name, id: contact.identifier, source: contact)
                    people.append(person)
                }
            } catch {
                print("Error fetching contacts")
            }
            
            self.models = people
            self.prepareSections(people)
        }
    }
    
    func prepareSections(_ people: [Person]) {
        var dict: [String: [Person]] = [:]
        
        for person in people {
            let key = String(person.name.prefix(1).uppercased())
            dict[key, default: []].append(person)
        }
        
        // Sort sections and people
        for (key, value) in dict {
            dict[key] = value.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        }
        
        let sortedTitles = dict.keys.sorted()
        
        DispatchQueue.main.async {
            self.contactDict = dict
            self.sectionTitles = sortedTitles
            self.filteredDict = dict
            self.filteredSectionTitles = sortedTitles
            self.tableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching() ? filteredSectionTitles.count : sectionTitles.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return isSearching() ? filteredSectionTitles : sectionTitles
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isSearching() ? filteredSectionTitles[section] : sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let title = isSearching() ? filteredSectionTitles[section] : sectionTitles[section]
        return (isSearching() ? filteredDict[title] : contactDict[title])?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title = isSearching() ? filteredSectionTitles[indexPath.section] : sectionTitles[indexPath.section]
        let person = isSearching() ? filteredDict[title]![indexPath.row] : contactDict[title]![indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = person.name
        return cell
    }
}
extension ViewController: UISearchResultsUpdating {
    func isSearching() -> Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text?.lowercased(), !text.isEmpty else {
            filteredDict = contactDict
            filteredSectionTitles = sectionTitles
            tableView.reloadData()
            return
        }
        
        var newDict: [String: [Person]] = [:]
        
        for (key, people) in contactDict {
            let filteredPeople = people.filter { $0.name.lowercased().contains(text) }
            if !filteredPeople.isEmpty {
                newDict[key] = filteredPeople
            }
        }
        
        filteredDict = newDict
        filteredSectionTitles = newDict.keys.sorted()
        tableView.reloadData()
    }
}

extension ViewController: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
        
        // If a new contact was saved
        if let contact = contact {
            let name = (contact.givenName + " " + contact.familyName).trimmingCharacters(in: .whitespaces)
            let person = Person(name: name, id: contact.identifier, source: contact)
            
            if !models.contains(where: { $0.id == person.id }) {
                models.append(person)
                prepareSections(models)
            }
        }
    }
}
