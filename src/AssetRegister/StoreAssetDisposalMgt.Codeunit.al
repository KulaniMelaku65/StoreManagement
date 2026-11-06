codeunit 60139 "Store Asset Disposal Mgt."
{
    // Disposal is a deliberate exception to the store-side "no approvals" rule -
    // it needs a genuine second person (the Asset Disposal Approver) to confirm
    // before the asset is actually considered disposed, rather than a single
    // one-click confirm like Asset Transfers or Store Requisitions get.
    Permissions = tabledata "Store Asset Register" = RM;

    procedure RequestDisposal(var AssetRegister: Record "Store Asset Register")
    begin
        AssetRegister.TestField("Disposal Method");
        if AssetRegister."Availability Status" = AssetRegister."Availability Status"::Issued then
            Error(CurrentlyIssuedErr);
        if AssetRegister."Disposal Status" = AssetRegister."Disposal Status"::PendingApproval then
            Error(AlreadyPendingErr);
        AssetRegister."Disposal Status" := AssetRegister."Disposal Status"::PendingApproval;
        AssetRegister."Disposal Requested Date" := Today();
        AssetRegister."Disposal Date" := 0D;
        AssetRegister."Disposal Approved By" := '';
        AssetRegister."Disposal Approval Date" := 0D;
        AssetRegister.Modify(true);
    end;

    procedure ApproveDisposal(var AssetRegister: Record "Store Asset Register")
    begin
        TestIsApprover();
        AssetRegister.TestField("Disposal Status", AssetRegister."Disposal Status"::PendingApproval);
        AssetRegister."Disposal Status" := AssetRegister."Disposal Status"::Approved;
        AssetRegister."Disposal Date" := Today();
        AssetRegister."Disposal Approved By" := CopyStr(UserId(), 1, MaxStrLen(AssetRegister."Disposal Approved By"));
        AssetRegister."Disposal Approval Date" := Today();
        AssetRegister."Availability Status" := AssetRegister."Availability Status"::Disposed;
        AssetRegister.Modify(true);
    end;

    procedure RejectDisposal(var AssetRegister: Record "Store Asset Register")
    begin
        TestIsApprover();
        AssetRegister.TestField("Disposal Status", AssetRegister."Disposal Status"::PendingApproval);
        AssetRegister."Disposal Status" := AssetRegister."Disposal Status"::Rejected;
        AssetRegister."Disposal Approved By" := CopyStr(UserId(), 1, MaxStrLen(AssetRegister."Disposal Approved By"));
        AssetRegister."Disposal Approval Date" := Today();
        AssetRegister.Modify(true);
    end;

    procedure UserIsDisposalApprover(): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId());
        AccessControl.SetRange("Role ID", 'ASSETDISPOSALAPPR');
        exit(not AccessControl.IsEmpty());
    end;

    local procedure TestIsApprover()
    begin
        if not UserIsDisposalApprover() then
            Error(NotApproverErr);
    end;

    var
        AlreadyPendingErr: Label 'A disposal request is already pending approval for this entry.';
        CurrentlyIssuedErr: Label 'This entry is currently issued to an employee - it must be returned to the store before disposal can be requested.';
        NotApproverErr: Label 'You do not have the Asset Disposal Approver permission set, so you cannot approve or reject a disposal request.';
}
