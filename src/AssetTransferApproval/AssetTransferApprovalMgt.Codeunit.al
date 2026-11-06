codeunit 60103 "Asset Transfer Approval Mgt."
{
    Permissions = tabledata "HR Asset Transfer Header" = RM;

    // No approval step: Confirm moves a transfer straight from Open to Approved,
    // which is what unlocks the Transfer action. Kept as its own step (rather than
    // folding into Transfer directly) so there's still a deliberate "this is correct,
    // go ahead" moment before the fixed asset's location/custodian actually changes.
    procedure Confirm(var AssetTransferHeader: Record "HR Asset Transfer Header")
    begin
        AssetTransferHeader.TestField(Status, AssetTransferHeader.Status::Open);
        AssetTransferHeader.Validate(Status, AssetTransferHeader.Status::Approved);
        AssetTransferHeader."Submitted By" := CopyStr(UserId(), 1, MaxStrLen(AssetTransferHeader."Submitted By"));
        AssetTransferHeader."Submitted Date" := Today();
        AssetTransferHeader."Approved By" := CopyStr(UserId(), 1, MaxStrLen(AssetTransferHeader."Approved By"));
        AssetTransferHeader."Approved Date" := Today();
        AssetTransferHeader.Modify(true);
        Message(ConfirmedMsg, AssetTransferHeader."No.");
    end;

    var
        ConfirmedMsg: Label 'Asset Transfer %1 is confirmed. The transfer can now be executed.', Comment = '%1 = document number';
}
