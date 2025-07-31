//
//  ViewController.swift
//  TravelBook
//
//  Created by Sadettin Karadavut on 2.02.2025.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate , CLLocationManagerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    var annotationTitle = ""
    var annotationComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        //        konumun ne kadar yakın olduğunu gösterir
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //        uygulama konumu ne zaman takip etsin
        locationManager.requestWhenInUseAuthorization()
        //        kullanıcının konumunu alır
        locationManager.startUpdatingLocation()
        
        //        üstüne uzun basıldığında seçme işlemi
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        //        klavye açıldıktan sonra viewa tıklandığında kaybolur
        let gestureRecognizerKeyboard = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(gestureRecognizerKeyboard)
        
                 

        if selectedTitle != "" {
                    //CoreData
                  
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let context = appDelegate.persistentContainer.viewContext
                    
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
                    let idString = selectedTitleId!.uuidString
                    fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                    fetchRequest.returnsObjectsAsFaults = false
                    
                    do {
                        let results = try context.fetch(fetchRequest)
                        if results.count > 0 {
                            
                            for result in results as! [NSManagedObject] {
                                
                                if let title = result.value(forKey: "title") as? String {
                                    annotationTitle = title
                                    
                                    if let subtitle = result.value(forKey: "subtitle") as? String {
                                        annotationComment = subtitle
                                        
                                        if let latitude = result.value(forKey: "latitude") as? Double {
                                            annotationLatitude = latitude
                                            
                                            if let longitude = result.value(forKey: "longitude") as? Double {
                                                annotationLongitude = longitude
                                                
                                                let annotation = MKPointAnnotation()
                                                annotation.title = annotationTitle
                                                annotation.subtitle = annotationComment
                                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                                annotation.coordinate = coordinate
                                                
                                                mapView.addAnnotation(annotation)
                                                nameText.text = annotationTitle
                                                commentText.text = annotationComment
                                                
                                                locationManager.stopUpdatingLocation()
                                                
                                                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                                let region = MKCoordinateRegion(center: coordinate, span: span)
                                                mapView.setRegion(region, animated: true)
                                                
                                                
                                            }
                                        }
                     
                                    }
                                }
                            }
                        }
                    } catch {
                        print("error")
                    }
                    
                    
                } else {
                    //Add New Data
                }
                
                
            }
    
    @IBAction func saveBtn(_ sender: Any) {
    
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
        
        //        core data entitysine erişme
                let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        //         title ,subtitle, coordinates ve id alma
                newPlace.setValue(nameText.text, forKey: "title")
                newPlace.setValue(commentText.text, forKey: "subtitle")
                newPlace.setValue(choosenLatitude, forKey: "latitude")
                newPlace.setValue(choosenLongitude, forKey: "longitude")
                newPlace.setValue(UUID(), forKey: "id")
                
                do {
                    try context.save()
                    print("success")
                } catch {
                    print("error")
                }
                
                NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
                navigationController?.popViewController(animated: true)
        
    }
    
    
    //    alert fonksiyonu
    func alertMessage(title: String, comment: String) {
        
        let alert = UIAlertController(title: title, message: comment, preferredStyle: .alert)
        let OkAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)
        alert.addAction(OkAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    //    keyboard kapatma func
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){

        //        kullanıcı uzun dokunmaya başladıysa
        if gestureRecognizer.state == .began{
            
            //            tıklanılan yerdeki lokasyonu alma
            let touchedPoint = gestureRecognizer.location(in: mapView)
            
            //            lokasyonun kordinatlarını alma
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            //            coordinateleri çekmek için değişkene bağladık
            choosenLatitude = touchedCoordinates.latitude
            choosenLongitude = touchedCoordinates.longitude
            
            //            pin oluşturma işlemi
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else{
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
//                closure
                if let placesmark = placemarks{
                    
                    if placesmark.count > 0{
                        let newPlacesmark = MKPlacemark(placemark: placesmark[0])
                        let item = MKMapItem(placemark: newPlacesmark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
            
        }
    }
    
    
    
    
    //    güncellenen lokasyonları bir dizi içersinde bize veriyor
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if selectedTitle == "" {
                //        kordinatımızın başlangıç yeri
                let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
                //        zoom seviyesi
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                //        nereye zomlanacağı
                let region = MKCoordinateRegion(center: location, span: span)
                mapView.setRegion(region, animated: true)
            } else {
                //
            }
        }
    
    }
    
    

