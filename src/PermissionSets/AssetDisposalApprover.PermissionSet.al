permissionset 60137 "ASSETDISPOSALAPPR"
{
    Assignable = true;
    Caption = 'Asset Disposal Approver';

    IncludedPermissionSets = "STOREKEEPER";

    Permissions =
        tabledata "Store Asset Register" = RIMD,
        page "Store Asset Register List" = X,
        codeunit "Store Asset Disposal Mgt." = X;
}
