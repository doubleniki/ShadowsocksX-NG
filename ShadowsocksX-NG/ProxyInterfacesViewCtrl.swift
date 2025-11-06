//
//  ProxyInterfacesTableViewCtrl.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 2017/3/17.
//  Copyright © 2017年 qiuyuzhou. All rights reserved.
//

import Cocoa
import RxCocoa
import RxSwift

class ProxyInterfacesViewCtrl: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var networkServices: NSArray?
    var selectedNetworkServices: NSMutableSet = NSMutableSet()

    @IBOutlet weak var tableView: NSTableView?
    @IBOutlet weak var autoConfigCheckBox: NSButton?

    /// Restores previously selected network services, loads the current list of network services, and refreshes the table view.
    /// 
    /// Reads the "Proxy4NetworkServices" array from UserDefaults to initialize `selectedNetworkServices`, queries `ProxyConfTool.networkServicesList()` to populate `networkServices`, and calls `reloadData()` on `tableView`.
    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard
        if let services = defaults.array(forKey: "Proxy4NetworkServices") {
            selectedNetworkServices = NSMutableSet(array: services)
        } else {
            selectedNetworkServices = NSMutableSet()
        }

        networkServices = ProxyConfTool.networkServicesList() as NSArray?
        tableView?.reloadData()
    }

    //--------------------------------------------------
    /// Provides the number of network services to display in the table view.
    /// - Returns: The number of available network services, or `0` if the service list is unavailable.
    func numberOfRows(in tableView: NSTableView) -> Int {
        return networkServices?.count ?? 0
    }

    /// Provides the button cell configured for the network service at the specified row.
    /// - Parameters:
    ///   - tableView: The table view requesting the cell.
    ///   - tableColumn: The column whose cell is requested; must contain an `NSButtonCell`.
    ///   - row: The row index of the network service.
    /// - Returns: The `NSButtonCell` whose `state` reflects whether the service's key is selected and whose `title` is the service's user-defined name, or `nil` if the column, cell, service data, or required fields are unavailable.
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?
        , row: Int) -> Any? {
        guard let tableColumn = tableColumn,
              let cell = tableColumn.dataCell as? NSButtonCell,
              let services = networkServices,
              row < services.count,
              let networkService = services[row] as? [String: Any],
              let key = networkService["key"] as? String,
              let userDefinedName = networkService["userDefinedName"] as? String else {
            return nil
        }

        cell.state = selectedNetworkServices.contains(key) ? .on : .off
        cell.title = userDefinedName
        return cell
    }

    /// Update the selected state for the network service at `row` based on the cell value and persist the change.
    /// - Parameters:
    ///   - object: The new cell value; expected to be an integer/`NSNumber` where `1` indicates checked and other values indicate unchecked.
    ///   - row: The table row index of the network service to update.
    /// 
    /// This updates `selectedNetworkServices` by adding or removing the service key and saves the resulting keys array to UserDefaults under the key "Proxy4NetworkServices".
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?
        , for tableColumn: NSTableColumn?, row: Int) {
        guard let services = networkServices,
              row < services.count,
              let networkService = services[row] as? [String: Any],
              let key = networkService["key"] as? String,
              let objectValue = object else {
            return
        }

        // Check if checkbox is checked
        if (objectValue as AnyObject).intValue == 1 {
            selectedNetworkServices.add(key)
        } else {
            selectedNetworkServices.remove(key)
        }

        UserDefaults.standard.set(selectedNetworkServices.allObjects,
                                  forKey: "Proxy4NetworkServices")
    }
}