import Contacts

class ContactListViewModel {
    private let store = CNContactStore()
    
    private(set) var models: [Person] = []
    private(set) var contactDict: [String: [Person]] = [:]
    private(set) var sectionTitles: [String] = []
    
    private(set) var filteredDict: [String: [Person]] = [:]
    private(set) var filteredSectionTitles: [String] = []
    
    var onDataUpdated: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    func requestAccess() {
        store.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            if let error = error {
                self.onError?(error)
                return
            }
            if granted {
                self.fetchContacts()
            } else {
                self.onError?(NSError(domain: "AccessDenied", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to contacts denied"]))
            }
        }
    }
    
    private func fetchContacts() {
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
                self.models = people
                self.prepareSections(people)
            } catch {
                DispatchQueue.main.async {
                    self.onError?(error)
                }
            }
        }
    }
    
    private func prepareSections(_ people: [Person]) {
        var dict: [String: [Person]] = [:]
        for person in people {
            let key = String(person.name.prefix(1).uppercased())
            dict[key, default: []].append(person)
        }
        
        for (key, value) in dict {
            dict[key] = value.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        }
        
        let sortedTitles = dict.keys.sorted()
        
        DispatchQueue.main.async {
            self.contactDict = dict
            self.sectionTitles = sortedTitles
            self.filteredDict = dict
            self.filteredSectionTitles = sortedTitles
            self.onDataUpdated?()
        }
    }
    
    func filterContacts(searchText: String) {
        if searchText.isEmpty {
            filteredDict = contactDict
            filteredSectionTitles = sectionTitles
        } else {
            var newDict: [String: [Person]] = [:]
            for (key, people) in contactDict {
                let filteredPeople = people.filter { $0.name.lowercased().contains(searchText.lowercased()) }
                if !filteredPeople.isEmpty {
                    newDict[key] = filteredPeople
                }
            }
            filteredDict = newDict
            filteredSectionTitles = newDict.keys.sorted()
        }
        onDataUpdated?()
    }
    
    func addNewContact(_ contact: CNContact) {
        let name = (contact.givenName + " " + contact.familyName).trimmingCharacters(in: .whitespaces)
        let person = Person(name: name, id: contact.identifier, source: contact)
        if !models.contains(where: { $0.id == person.id }) {
            models.append(person)
            prepareSections(models)
        }
    }
}
