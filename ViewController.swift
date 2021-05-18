//
//  ViewController.swift
//  MyHealthJournal
//
//  Created by Kai Moore on 2021/05/08.
//

import UIKit

class Section: Codable {
    let title: String
    let options: [String]
    var isOpened: Bool = false
    
    init(title: String, options: [String], isOpened: Bool = false) {
        self.title = title
        self.options = options
        self.isOpened = isOpened
    }
}

extension URL {
    static var sections: URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "company name"
        let subDirectory = applicationSupport.appendingPathComponent(bundleID, isDirectory: true)
        try? FileManager.default.createDirectory(at: subDirectory, withIntermediateDirectories: true, attributes: nil)
        return subDirectory.appendingPathComponent("sections.json")
    }
}

class Shared {
    static let instance = Shared()
    private init() { }
    var sections: [Section] {
        get {
            guard let data = try? Data(contentsOf: .sections) else { return [] }
            return (try? JSONDecoder().decode([Section].self, from: data)) ?? []
        }
        set {
            try? JSONEncoder().encode(newValue).write(to: .sections)
        }
    }
}

class JournalViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private var sections = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Journal"
        
        sections = Shared.instance.sections
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
    }
    
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "New Journal Entry", message: "", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Enter date..."
        }
        alert.addTextField { field in
            field.placeholder = "Enter journal entry..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
            if let dateField = alert.textFields?[0], let entryField = alert.textFields?[1] {
                if let dateText = dateField.text, let entryText = entryField.text, !dateText.isEmpty, !entryText.isEmpty {
                    DispatchQueue.main.async {
                        self.sections.append(Section(title: dateText, options: ["   " + entryText]))
                        self.tableView.reloadData()
                        Shared.instance.sections.append(Section(title: dateText, options: ["   " + entryText]))
                    }
                }
            }
        }))
        present(alert, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        if section.isOpened {
            return section.options.count + 1
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = sections[indexPath.section].title
        }
        else {
            cell.textLabel?.text = sections[indexPath.section].options[indexPath.row - 1]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            sections[indexPath.section].isOpened = !sections[indexPath.section].isOpened
            tableView.reloadSections([indexPath.section], with: .none)
        }
    }
}

class MedicineViewController: UIViewController, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    var items = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.items = UserDefaults.standard.stringArray(forKey: "medicines") ?? []
        title = "Medicines"
        view.addSubview(tableView)
        tableView.dataSource = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
    }
    
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "New Medicine Entry", message: "", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Enter medicine..."
        }
        alert.addTextField { field in
            field.placeholder = "Enter other stuff..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self] (_) in
            if let field = alert.textFields?[0] {
                if let text = field.text, !text.isEmpty {
                    DispatchQueue.main.async {
                        var currentItems = UserDefaults.standard.stringArray(forKey: "medicines") ?? []
                        currentItems.append(text)
                        UserDefaults.standard.setValue(currentItems, forKey: "medicines")
                        self?.items.append(text)
                        self?.tableView.reloadData()
                    }
                }
            }
        }))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            items.remove(at: indexPath.row)
            UserDefaults.standard.setValue(items, forKey: "medicines")
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
}

class ClinicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()
    
    private var sections = [Section]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Clinics"
        
        sections = [
            Section(title: "Clinic A", options: ["   Address: 1234 NW Clinic St Portland, OR", "   (503) 123-4567"]),
            Section(title: "Hospital B", options: ["   Address: 5678 SE Hospital St Portland, OR", "   (971) 765-4321"]),
            Section(title: "Dentist C", options: ["   Address: 9876 SW Dentist St Portland, OR", "   (503) 321-7654"])
        ]
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        if section.isOpened {
            return section.options.count + 1
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = sections[indexPath.section].title
        }
        else {
            
            cell.textLabel?.text = sections[indexPath.section].options[indexPath.row - 1]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            sections[indexPath.section].isOpened = !sections[indexPath.section].isOpened
            tableView.reloadSections([indexPath.section], with: .none)
        }
    }
}
