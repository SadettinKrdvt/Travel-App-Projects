//
//  ListViewController.swift
//  TravelBook
//
//  Created by Sadettin Karadavut on 3.02.2025.
//

import UIKit
import CoreData

class ListViewController: UIViewController ,UITableViewDelegate,UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    var idArray = [UUID]()
    var titleArray = [String]()
    var choosenTitle = ""
    var choosenTitleId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        sağ üstte navigation bar oluşturma
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonTapped))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        getData()

        
    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
        
    }
    
    @objc func getData(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            
            if results.count > 0{
                
//                loopa girmeden tableViewdaki verileri tekrar tekrar kayıt etmesin diye siler
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
//                core data metodlarına ulaşmak için
                for result in results as! [NSManagedObject]{
                    
                    if let title = result.value(forKey: "title") as? String{
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                }
            }
            
        }catch{
         
            print("Error!")
            
        }
        
    }
    
//    2. view controllera geçiş yapma
    @objc func addButtonTapped(){
        choosenTitle = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = titleArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choosenTitle = titleArray[indexPath.row]
        choosenTitleId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC"{
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = choosenTitle
            destinationVC.selectedTitleId = choosenTitleId
            
        }
    }
    

   

}
