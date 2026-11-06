page 60105 "Store Keeper Role Center"
{
    PageType = RoleCenter;
    Caption = 'Store Keeper';

    layout
    {
        area(rolecenter)
        {
            part(Headline; "Store Keeper Headline")
            {
                ApplicationArea = All;
            }
            part(Activities; "Store Keeper Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    // Three menu groups, each its own drop-down in the navigation bar:
    // Store Operations (the daily documents), Assets and Inventory (the two
    // registers with their summaries and setup lists).
    // No Purchase Orders / Posted Purchase Invoices entries: the Approved
    // Purchase Orders and Purchase Invoices Ready tiles on the home page open
    // those lists. No Items / Fixed Assets lists either: the registers are the
    // store keeper's working records, and Finance owns the Item and Fixed Asset
    // cards.
    actions
    {
        area(sections)
        {
            group(StoreOperations)
            {
                Caption = 'Store Operations';

                action(StoreRequisitions)
                {
                    Caption = 'Store Requisitions';
                    ToolTip = 'Requests raised by staff for items or minor assets, in any status.';
                    Image = OrderList;
                    RunObject = page "Store Req. Approval List";
                    ApplicationArea = All;
                }
                action(RequisitionsToIssue)
                {
                    Caption = 'Requisitions to Issue';
                    ToolTip = 'Requisitions approved by the Store Manager, ready for you to hand over the items and post.';
                    Image = ReleaseDoc;
                    RunObject = page "Store Req. Approval List";
                    RunPageView = where(Status = filter(Released));
                    ApplicationArea = All;
                }
                action(GoodsReceived)
                {
                    Caption = 'Goods Received Notes';
                    ToolTip = 'Stock received into the store against a purchase order.';
                    Image = PostedReceipts;
                    RunObject = page "Custom GRN Header";
                    ApplicationArea = All;
                }
                action(EmployeeItems)
                {
                    Caption = 'Items Issued to Staff';
                    ToolTip = 'Items currently allocated to an employee, and where to return them once handed back.';
                    Image = ItemAvailability;
                    RunObject = page "Employee Items";
                    ApplicationArea = All;
                }
                action(IssueReturnHistory)
                {
                    Caption = 'Issue and Return History';
                    ToolTip = 'Everything issued to staff and when it was returned, newest first.';
                    Image = History;
                    RunObject = page "Store Issue Return History";
                    ApplicationArea = All;
                }
                action(AssetTransfers)
                {
                    Caption = 'Asset Transfers';
                    ToolTip = 'Requests to move a fixed or minor asset to a new location or a new responsible employee.';
                    Image = TransferOrder;
                    RunObject = page "Store Asset Transfer List";
                    ApplicationArea = All;
                }
            }
            group(Assets)
            {
                Caption = 'Assets';

                action(AssetRegister)
                {
                    Caption = 'Asset Register';
                    ToolTip = 'Physical count register for tagged and bulk-counted assets by category, zone, and shelf - matches the warehouse count spreadsheets.';
                    Image = ItemGroup;
                    RunObject = page "Store Asset Register List";
                    ApplicationArea = All;
                }
                action(AssetRegisterSummary)
                {
                    Caption = 'Asset Register Summary';
                    ToolTip = 'Rolled-up totals by Asset Class, Type, Description, and Model - e.g. "12 Duos / Samsung" - with drill-down to the individual tagged units.';
                    Image = Statistics;
                    RunObject = page "Store Asset Register Summary";
                    ApplicationArea = All;
                }
                action(AssetCategories)
                {
                    Caption = 'Asset Categories';
                    ToolTip = 'Add or rename the category codes used on the Asset Register.';
                    Image = Category;
                    RunObject = page "Store Asset Categories";
                    ApplicationArea = All;
                }
                action(AssetTypes)
                {
                    Caption = 'Asset Types';
                    ToolTip = 'Add or rename the type codes (Laptop, Desktop, Chair, etc.) used to build Tag Numbers on the Asset Register.';
                    Image = ItemGroup;
                    RunObject = page "Store Asset Types";
                    ApplicationArea = All;
                }
            }
            group(Inventory)
            {
                Caption = 'Inventory';

                action(InventoryRegister)
                {
                    Caption = 'Inventory Register';
                    ToolTip = 'Consumables and stock items (stationery, cleaning supplies, toner, etc.) tracked by quantity - book quantity vs. physical count, with the variance.';
                    Image = Inventory;
                    RunObject = page "Store Inventory Register List";
                    ApplicationArea = All;
                }
                action(InventoryRegisterSummary)
                {
                    Caption = 'Inventory Register Summary';
                    ToolTip = 'One row per item: total quantity, physical count, variance and cost, rolled up from the Inventory Register.';
                    Image = Statistics;
                    RunObject = page "Store Inv. Register Summary";
                    ApplicationArea = All;
                }
                action(InventoryCategories)
                {
                    Caption = 'Inventory Categories';
                    ToolTip = 'Add or rename the category codes used on the Inventory Register.';
                    Image = Category;
                    RunObject = page "Store Inventory Categories";
                    ApplicationArea = All;
                }
            }
        }
    }
}
