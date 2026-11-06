permissionset 60160 "STOREREQUESTER"
{
    Assignable = true;
    Caption = 'Store Requester';

    // For any employee who raises Store Requisitions. Choosing an asset or item
    // on a requisition line reads the Asset and Inventory Registers (to fill in
    // the Tag No. and Issuing Store, and to list available tags), so requesters
    // need read access to both. They cannot change either register.
    Permissions =
        tabledata "Store Asset Register" = R,
        tabledata "Store Inventory Register" = R,
        tabledata Location = R,
        tabledata "Fixed Asset" = R,
        tabledata Item = R,
        tabledata "PROC-Store Requistion Header" = RIM,
        tabledata "PROC-Store Requistion Lines" = RIMD,
        // The pick-lists on a requisition line open these two register lists.
        codeunit "Store Employee Name Mgt." = X,
        page "Store Asset Lookup" = X,
        page "Store Inventory Lookup" = X,
        page "Store Asset Register List" = X,
        page "Store Inventory Register List" = X;
}
