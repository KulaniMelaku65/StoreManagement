codeunit 60158 "Store PO GRN Mgt."
{
    // Our own "Create GRN" for a released Purchase Order. Fanisi_Finance's
    // Generate GRN (Header Management.GenerateGRN) is a compiled app we can't
    // change, and it was failing with "The type NavOption is unknown." - so this
    // does the same job (same GRN header/line fields, same No. Series, same
    // GRN No./GRN Generated stamp on the order) in our own code, mirroring
    // Posted Invoice GRN Mgt. for posted invoices. Records are written without
    // running the base table triggers, since those are what we can't see into.
    Permissions = tabledata "Custom GRN Header" = RIM, tabledata "Custom GRN Lines" = RIM, tabledata "Purchase Header" = RM, tabledata "Purchase Line" = R;

    procedure GenerateGRNFromOrder(var PurchHeader: Record "Purchase Header")
    var
        GRNHeader: Record "Custom GRN Header";
        GRNLine: Record "Custom GRN Lines";
        PurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        StoreGRNLineSplitMgt: Codeunit "Store GRN Line Split Mgt.";
        NextNo: Code[30];
        LineNo: Integer;
    begin
        PurchHeader.TestField(Status, PurchHeader.Status::Released);
        PurchHeader.TestField("GRN Generated", false);

        PurchSetup.Get();
        PurchSetup.TestField("Manual GRN");
        NextNo := NoSeriesMgt.GetNextNo(PurchSetup."Manual GRN", Today(), true);

        GRNHeader.Init();
        GRNHeader."No." := NextNo;
        GRNHeader."Order No." := PurchHeader."No.";
        GRNHeader."Document Date" := Today();
        GRNHeader."Department Code" := PurchHeader."Shortcut Dimension 1 Code";
        GRNHeader."Order date" := PurchHeader."Order Date";
        GRNHeader."Vendor No." := PurchHeader."Buy-from Vendor No.";
        GRNHeader."Vendor Name" := PurchHeader."Buy-from Vendor Name";
        GRNHeader."Vendor Invoice No." := PurchHeader."Vendor Invoice No.";
        GRNHeader.Username := CopyStr(UserId(), 1, MaxStrLen(GRNHeader.Username));
        PurchHeader.CalcFields("Amount Including VAT");
        GRNHeader."LPO Amount" := PurchHeader."Amount Including VAT";
        GRNHeader."Date Received" := Today();
        GRNHeader.Insert(false);

        LineNo := 0;
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchLine.FindSet() then
            repeat
                if (PurchLine.Type <> PurchLine.Type::" ") and (PurchLine.Quantity > 0) then begin
                    LineNo += 1;
                    GRNLine.Init();
                    GRNLine."Type" := PurchLine.Type;
                    GRNLine."No." := PurchLine."No.";
                    GRNLine."Document No." := NextNo;
                    GRNLine."Line No" := LineNo;
                    GRNLine.Description := PurchLine.Description;
                    // The purchase line text is a model/spec description (e.g.
                    // "Samsung A16 4GB 128 GB storage"), so a Fixed Asset line
                    // carries it into Model. The Asset Register's own Description
                    // then comes from the Fixed Asset card, not from here.
                    if PurchLine.Type = PurchLine.Type::"Fixed Asset" then
                        GRNLine.Model := CopyStr(PurchLine.Description, 1, MaxStrLen(GRNLine.Model));
                    GRNLine."Document Date" := Today();
                    GRNLine."Unit Of Measure" := PurchLine."Unit of Measure";
                    GRNLine."Location Code" := PurchLine."Location Code";
                    GRNLine."Quantity Ordered" := PurchLine.Quantity;
                    GRNLine."Quantity To Receive" := PurchLine.Quantity;
                    GRNLine."Unit Cost" := PurchLine."Direct Unit Cost";
                    GRNLine."Line Amount" := PurchLine."Direct Unit Cost" * PurchLine.Quantity;
                    GRNLine."Unit Cost Incl. VAT" := Round(PurchLine."Direct Unit Cost" * (1 + PurchLine."VAT %" / 100), 0.00001);
                    GRNLine."Line Amount Incl. VAT" := Round(GRNLine."Unit Cost Incl. VAT" * PurchLine.Quantity, 0.01);
                    GRNLine.Insert(false);
                end;
            until PurchLine.Next() = 0;

        PurchHeader."GRN Generated" := true;
        PurchHeader."GRN No." := NextNo;
        PurchHeader.Modify(false);

        StoreGRNLineSplitMgt.SplitMultiUnitLines(NextNo);

        Page.Run(Page::"Custom GRN Card", GRNHeader);
    end;
}
