codeunit 60159 "Store Req. Approval Mgt."
{
    // Approval step before anything leaves the store. The employee raises the
    // requisition; only a Store Manager can approve it (Open -> Released); only
    // then can the store keeper issue and post it. Fanisi's own approval
    // workflow is switched off and can't be changed, so this is our own check.
    Permissions = tabledata "PROC-Store Requistion Header" = RM, tabledata "Access Control" = R;

    procedure ApproveForIssue(var RequisitionHeader: Record "PROC-Store Requistion Header")
    begin
        RequisitionHeader.TestField(Status, RequisitionHeader.Status::Open);

        if not IsStoreManager() then
            Error(NotManagerErr);

        // Nobody approves their own request, even a manager.
        if RequisitionHeader.SystemCreatedBy = UserSecurityId() then
            Error(OwnRequestErr);

        RequisitionHeader.Validate(Status, RequisitionHeader.Status::Released);
        RequisitionHeader."Approved By" := CopyStr(UserId(), 1, MaxStrLen(RequisitionHeader."Approved By"));
        RequisitionHeader."Approved Date" := Today();
        RequisitionHeader.Modify(true);
        Message(ApprovedMsg, RequisitionHeader."No.");
    end;

    // Also used by the home page headline to say which role the user is in.
    procedure IsStoreManager(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetFilter("Role ID", 'STOREKEEPERMGR|SUPER');
        exit(not AccessControl.IsEmpty());
    end;

    var
        NotManagerErr: Label 'Only a Store Manager can approve a store requisition for issue.';
        OwnRequestErr: Label 'You cannot approve a store requisition that you created yourself.';
        ApprovedMsg: Label 'Store requisition %1 is approved. The store keeper can now issue it.', Comment = '%1 = requisition number';
}
