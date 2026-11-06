permissionset 60101 "STOREKEEPERMGR"
{
    Assignable = true;
    Caption = 'Store Keeper Manager';

    IncludedPermissionSets = "STOREKEEPER";

    Permissions =
        tabledata "PROC-Store Requistion Header" = RM,
        tabledata "HR Asset Transfer Header" = RIMD,
        tabledata "HR Asset Transfer Lines" = RIMD,
        // Risk module (Fanisi_Finance) - Store Keeper Manager is the intended Risk Owner
        // for asset-related risk entries (theft, damage, loss, unauthorized use).
        tabledata "RSK-Risk Identification" = RIMD,
        tabledata "RSK-Risk Analysis Assessment" = RIMD,
        tabledata "Risk Response" = RIMD,
        tabledata "Risk Monitoring" = RIMD,
        tabledata "Post Treatment Risk Assessment" = RIMD,
        // Physical inventory posting - the counterpart to STOREKEEPER's entry-only access.
        // Posting an Item Journal line creates ledger entries, so those tables need
        // write access here even though STOREKEEPER only has Read on them.
        tabledata "Item Ledger Entry" = RIMD,
        tabledata "Value Entry" = RIMD,

        page "Risk Identification List" = X,
        page "Risk Identification Card" = X,
        page "Risk Analysis List" = X,
        page "Risk Response List" = X,
        page "Risk Monitoring List" = X,
        page "Post Risk Assessment List" = X,

        codeunit "Item Jnl.-Post Line" = X,
        codeunit "Item Jnl.-Post Batch" = X;
}
