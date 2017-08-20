//
//  ViewController.swift
//  rx_laptimer
//
//  Created by Marin Todorov on 2/15/16.
//  Copyright © 2016 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
  
  @IBOutlet weak var lblChrono: UILabel!
  @IBOutlet weak var btnLap: UIButton!
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var btnPlay: UIButton!
  @IBOutlet weak var btnStop: UIButton!
  
  let tableHeaderView = UILabel()
  
  let bag = DisposeBag()
  var timer: Observable<Int>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableHeaderView.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
    
    let isRunning = Observable
      .merge([btnPlay.rx.tap.map({ return true }), btnStop.rx.tap.map({ return false })])
      .startWith(false)
      .shareReplayLatestWhileConnected()
    
    isRunning
      .subscribe(onNext: {
        print($0)
      })
      .addDisposableTo(bag)
    
    let isntRunning = isRunning
      .map({running -> Bool in
        print(running)
        return !running
      })
      .shareReplay(1)
    
    isRunning
      .bindTo(btnStop.rx.isEnabled)
      .addDisposableTo(bag)
    
    isntRunning
      .bindTo(btnLap.rx.isHidden)
      .addDisposableTo(bag)
    
    isntRunning
      .bindTo(btnPlay.rx.isEnabled)
      .addDisposableTo(bag)
    
    //create the timer
    timer = Observable<Int>
      .interval(0.1, scheduler: MainScheduler.instance)
      .withLatestFrom(isRunning, resultSelector: {_, running in running})
      .filter({running in running})
      .scan(0, accumulator: {(acc, _) in
        return acc+1
      })
      .startWith(0)
      .shareReplayLatestWhileConnected()
    
    timer
      .subscribe { (msecs) in
        print("\(msecs)00ms")
      }
      .addDisposableTo(bag)
    
    //wire the chrono
    timer.map(stringFromTimeInterval)
      .bindTo(lblChrono.rx.text)
      .addDisposableTo(bag)
    
    let lapsSequence = timer
      .sample(btnLap.rx.tap)
      .map(stringFromTimeInterval)
      .scan([String](), accumulator: { lapTimes, newTime in
        return lapTimes + [newTime]
      })
      .shareReplayLatestWhileConnected()
    
    lapsSequence
      .bindTo(tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, element, cell) in
        cell.textLabel?.text = "\(row+1)) \(element)"
      }
      .addDisposableTo(bag)
    
    //set table delegate
    tableView
      .rx.setDelegate(self)
      .addDisposableTo(bag)
    
    //update the table header
    lapsSequence.map({ laps -> String in
      return "\t\(laps.count) laps"
    })
      .startWith("\tno laps")
      .bindTo(tableHeaderView.rx.text)
      .addDisposableTo(bag)
    
  }
}

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return tableHeaderView
  }
}

func stringFromTimeInterval(_ ms: NSInteger) -> String {
  return String(format: "%0.2d:%0.2d.%0.1d",
                arguments: [(ms / 600) % 600, (ms % 600 ) / 10, ms % 10])
}
