codeunit 60162 "Store Requisition Post Mgt."
{
    // Posting a store requisition.
    //
    // Fanisi's own posting (Process Store Requisition) turns every requisition
    // line into an Item Journal line using the line's No. as an Item No., which
    // fails for a Minor Asset line (its No. is a Fixed Asset, not an Item) with
    // "The field Item No. ... cannot be found in the related table (Item)".
    // Assets aren't stock, so they need no item journal: issuing one just means
    // recording who has it. So:
    //   - Minor Asset lines only  -> posted here, no item journal.
    //   - Item lines only         -> Fanisi's posting, as before.
    //   - Both on one requisition -> refused; raise them as two requisitions.
    Permissions = tabledata "PROC-Store Requistion Header" = RM, tabledata "PROC-Store Requistion Lines" = RM, tabledata "Store Asset Register" = R;

    procedure PostRequisition(var RequisitionHeader: Record "PROC-Store Requistion Header")
    var
        RequisitionLine: Record "PROC-Store Requistion Lines";
        StoreRequisitionIssueMgt: Codeunit "Store Requisition Issue Mgt.";
        ProcessStoreRequisition: Codeunit "Process Store Requisition";
        HasItemLines: Boolean;
        HasAssetLines: Boolean;
    begin
        RequisitionHeader.TestField(Status, RequisitionHeader.Status::Released);

        RequisitionLine.SetRange("Requistion No", RequisitionHeader."No.");
        if RequisitionLine.FindSet() then
            repeat
                case RequisitionLine.Type of
                    RequisitionLine.Type::Item:
                        HasItemLines := true;
                    RequisitionLine.Type::"Minor Asset":
                        HasAssetLines := true;
                end;
            until RequisitionLine.Next() = 0;

        if not (HasItemLines or HasAssetLines) then
            Error(NoLinesErr);
        if HasItemLines and HasAssetLines then
            Error(MixedLinesErr);

        if HasItemLines then begin
            // Stock items: Fanisi's posting does the item journal.
            ProcessStoreRequisition.postStoreRequistion(RequisitionHeader);
            RequisitionHeader.Get(RequisitionHeader."No.");
            if RequisitionHeader.Status = RequisitionHeader.Status::Posted then
                StoreRequisitionIssueMgt.CreateEmployeeItemsForRequisition(RequisitionHeader);
            exit;
        end;

        PostAssetRequisition(RequisitionHeader, RequisitionLine);
        StoreRequisitionIssueMgt.CreateEmployeeItemsForRequisition(RequisitionHeader);
        Message(AssetsIssuedMsg, RequisitionHeader."No.", RequisitionHeader."Employee Name");
    end;

    local procedure PostAssetRequisition(var RequisitionHeader: Record "PROC-Store Requistion Header"; var RequisitionLine: Record "PROC-Store Requistion Lines")
    var
        AssetRegister: Record "Store Asset Register";
    begin
        RequisitionHeader.TestField("Employee No.");

        RequisitionLine.Reset();
        RequisitionLine.SetRange("Requistion No", RequisitionHeader."No.");
        RequisitionLine.FindSet(true);
        repeat
            if RequisitionLine."Tag No." = '' then
                Error(TagMissingErr, RequisitionLine."No.");
            AssetRegister.SetRange("Tag No.", RequisitionLine."Tag No.");
            AssetRegister.FindFirst();
            if AssetRegister."Availability Status" <> AssetRegister."Availability Status"::Available then
                Error(TagNotAvailableErr, RequisitionLine."Tag No.");
            // A tagged unit is exactly one item.
            RequisitionLine."Quantity Issued" := 1;
            RequisitionLine.Modify(false);
        until RequisitionLine.Next() = 0;

        RequisitionHeader.Status := RequisitionHeader.Status::Posted;
        RequisitionHeader."Issue Date" := Today();
        RequisitionHeader.Modify(false);
    end;

    var
        NoLinesErr: Label 'This requisition has no Item or Minor Asset lines to issue.';
        MixedLinesErr: Label 'This requisition mixes stock Items and Minor Assets. Please raise them as two separate requisitions, one for the items and one for the assets.';
        TagMissingErr: Label 'Select the Tag No. for asset %1 before posting, so the system knows which physical unit is leaving the store.', Comment = '%1 = fixed asset number';
        TagNotAvailableErr: Label 'Tag No. %1 is not available - it may already be issued or disposed.', Comment = '%1 = tag number';
        AssetsIssuedMsg: Label 'Requisition %1 is posted. The assets are now recorded as issued to %2.', Comment = '%1 = requisition number, %2 = employee name';
}
