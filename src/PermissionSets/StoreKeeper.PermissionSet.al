permissionset 60100 "STOREKEEPER"
{
    Assignable = true;
    Caption = 'Store Keeper';

    Permissions =
        // Read-only - Finance creates Item cards, the store keeper only links
        // register rows to Items that already exist.
        tabledata Item = R,
        tabledata Location = R,
        tabledata "Item Ledger Entry" = R,
        // Read-only - Finance owns Fixed Asset cards entirely, including serial
        // numbers and location. The store keeper only views them.
        tabledata "Fixed Asset" = R,
        tabledata "FA Location" = R,
        tabledata "PROC-Store Requistion Header" = RM,
        tabledata "PROC-Store Requistion Lines" = RM,
        tabledata "PROC-Store Issue Header" = R,
        tabledata "PROC-Store Issue Line" = R,
        tabledata "Custom GRN Header" = RIMD,
        tabledata "Custom GRN Lines" = RIMD,
        tabledata "HR Asset Transfer Header" = RM,
        tabledata "HR Asset Transfer Lines" = RM,
        tabledata "Store Keeper Cue" = RIM,
        tabledata "Employee Items" = RIM,
        tabledata "Store Asset Register" = RIMD,
        tabledata "Store Asset Category" = RIMD,
        tabledata "Store Asset Transfer" = RIMD,
        tabledata Employee = R,
        tabledata "Store Asset Type" = RIMD,
        tabledata "Store Asset Register Summary" = RIMD,
        tabledata "Store Inventory Register" = RIMD,
        tabledata "Store Inv. Register Summary" = RIMD,
        tabledata "Store Inventory Category" = RIMD,
        // View + trigger "Generate GRN" only - Store Keeper isn't meant to create,
        // approve, or post purchase documents themselves.
        tabledata "Purchase Header" = RM,
        tabledata "Purchase Line" = R,
        // Create GRN takes the next number from the GRN No. Series.
        tabledata "Purchases & Payables Setup" = R,
        tabledata "No. Series" = R,
        tabledata "No. Series Line" = RM,
        // Create GRN runs from the posted invoice, so it needs Modify (to stamp
        // GRN Generated/GRN No.) rather than just Read.
        tabledata "Purch. Inv. Header" = RM,
        tabledata "Purch. Inv. Line" = R,
        // Physical count entry only - deliberately no Execute on the Item Jnl.-Post
        // codeunits, so a Store Keeper can enter counts but cannot post the adjustment
        // themselves. Posting stays with STOREKEEPERMGR (see that permission set).
        tabledata "Item Journal Line" = RIMD,
        tabledata "Item Journal Batch" = RIM,
        tabledata "Item Journal Template" = R,

        page "Item List" = X,
        page "Phys. Inventory Journal" = X,
        // "Calculate Inventory" fills the journal with the items to count.
        report "Calculate Inventory" = X,
        page "Item Card" = X,
        page "PROC-Store Requisition" = X,
        page "Store Req. Approval List" = X,
        page "All Store Requisition" = X,
        page "PROC-Store Req. Header (B)" = X,
        page "PROC-Store Requisition Line UP" = X,
        page "Custom GRN Header" = X,
        page "Custom GRN Card" = X,
        page "Custom GRN Lines" = X,
        page "HR Asset Transfer List" = X,
        page "Hr Asset  Transfer Header" = X,
        page "Fixed Asset List" = X,
        page "Store Keeper Activities" = X,
        page "Store Keeper Headline" = X,
        page "Purchase Invoice" = X,
        page "Purchase Order" = X,
        page "Posted Purchase Invoice" = X,
        page "Posted Purchase Invoices" = X,
        page "Employee Items" = X,
        page "Store Asset Lookup" = X,
        page "Store Inventory Lookup" = X,
        page "Store Asset Register List" = X,
        page "Store Asset Transfer List" = X,
        page "Store Asset Transfer Card" = X,
        page "Store Asset Categories" = X,
        page "Store Asset Types" = X,
        page "Store Asset Register Summary" = X,
        page "Store Inventory Register List" = X,
        page "Store Inv. Register Summary" = X,
        page "Store Issue Return History" = X,
        page "Store Inventory Categories" = X,
        codeunit "Store Asset Register Import" = X,
        codeunit "Store Asset Tag Mgt." = X,
        codeunit "Store Asset Disposal Mgt." = X,
        codeunit "Store Asset Register GRN Mgt." = X,
        codeunit "Store Asset Return Mgt." = X,
        codeunit "Store Inv. Register Import" = X,
        codeunit "Store GRN Line Split Mgt." = X,
        codeunit "Store PO GRN Mgt." = X,
        codeunit "Store Employee Name Mgt." = X,
        codeunit "Store Asset Transfer Mgt." = X,
        codeunit "Store Greeting Mgt." = X,
        codeunit "Store Requisition Post Mgt." = X,
        codeunit "Store Requisition Issue Mgt." = X,
        // Runs the Approve for Issue action, which refuses anyone who isn't a
        // Store Manager with a clear message rather than a raw permission error.
        codeunit "Store Req. Approval Mgt." = X,
        codeunit "Posted Invoice GRN Mgt." = X,
        codeunit "Store Inv. Register GRN Mgt." = X;
}
