codeunit 60120 "Posted Invoice GRN Mgt."
{
    // Fanisi_Finance's GenerateGRN (Header Management codeunit) only accepts the
    // unposted "Purchase Header" - a Posted Purchase Invoice is a different table
    // ("Purch. Inv. Header"/"Purch. Inv. Line") with no relation to it, so GRN
    // creation from a posted invoice needs its own copy of that logic rather than
    // reusing the external procedure.
    Permissions = tabledata "Custom GRN Header" = RIM, tabledata "Custom GRN Lines" = RIM, tabledata "Purch. Inv. Header" = RM;

    procedure GenerateGRNFromPostedInvoice(var PostedInvoiceHeader: Record "Purch. Inv. Header")
    var
        GRNHeader: Record "Custom GRN Header";
        GRNLine: Record "Custom GRN Lines";
        PostedInvoiceLine: Record "Purch. Inv. Line";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NextNo: Code[30];
        LineNo: Integer;
    begin
        PostedInvoiceHeader.TestField("GRN Generated", false);

        PurchSetup.Get();
        PurchSetup.TestField("Manual GRN");
        NextNo := NoSeriesMgt.GetNextNo(PurchSetup."Manual GRN", Today(), true);

        GRNHeader.Init();
        GRNHeader."No." := NextNo;
        GRNHeader."Order No." := PostedInvoiceHeader."No.";
        GRNHeader."Document Date" := Today();
        GRNHeader."Department Code" := PostedInvoiceHeader."Shortcut Dimension 1 Code";
        GRNHeader."Order date" := PostedInvoiceHeader."Order Date";
        GRNHeader."Vendor No." := PostedInvoiceHeader."Buy-from Vendor No.";
        GRNHeader."Vendor Name" := PostedInvoiceHeader."Buy-from Vendor Name";
        GRNHeader."Vendor Invoice No." := PostedInvoiceHeader."Vendor Invoice No.";
        GRNHeader.Username := CopyStr(UserId(), 1, MaxStrLen(GRNHeader.Username));
        PostedInvoiceHeader.CalcFields("Amount Including VAT");
        GRNHeader."LPO Amount" := PostedInvoiceHeader."Amount Including VAT";
        GRNHeader."Date Received" := Today();
        GRNHeader.Insert();

        LineNo := 0;
        PostedInvoiceLine.SetRange("Document No.", PostedInvoiceHeader."No.");
        if PostedInvoiceLine.FindSet() then
            repeat
                LineNo += 1;
                GRNLine.Init();
                GRNLine."Type" := PostedInvoiceLine.Type;
                GRNLine."No." := PostedInvoiceLine."No.";
                GRNLine."Document No." := NextNo;
                GRNLine."Line No" := LineNo;
                GRNLine.Description := PostedInvoiceLine.Description;
                // Same as Create GRN from a Purchase Order: the line text is the
                // model/spec description for a Fixed Asset.
                if PostedInvoiceLine.Type = PostedInvoiceLine.Type::"Fixed Asset" then
                    GRNLine.Model := CopyStr(PostedInvoiceLine.Description, 1, MaxStrLen(GRNLine.Model));
                GRNLine."Document Date" := Today();
                GRNLine."Unit Of Measure" := PostedInvoiceLine."Unit of Measure";
                GRNLine."Location Code" := PostedInvoiceLine."Location Code";
                GRNLine."Quantity Ordered" := PostedInvoiceLine.Quantity;
                GRNLine."Quantity To Receive" := PostedInvoiceLine.Quantity;
                GRNLine."Unit Cost" := PostedInvoiceLine."Direct Unit Cost";
                GRNLine."Line Amount" := PostedInvoiceLine."Direct Unit Cost" * PostedInvoiceLine.Quantity;
                GRNLine."Unit Cost Incl. VAT" := Round(PostedInvoiceLine."Direct Unit Cost" * (1 + PostedInvoiceLine."VAT %" / 100), 0.00001);
                GRNLine."Line Amount Incl. VAT" := Round(GRNLine."Unit Cost Incl. VAT" * PostedInvoiceLine.Quantity, 0.01);
                GRNLine.Insert();
            until PostedInvoiceLine.Next() = 0;

        PostedInvoiceHeader."GRN Generated" := true;
        PostedInvoiceHeader."GRN No." := NextNo;
        PostedInvoiceHeader.Modify();

        StoreGRNLineSplitMgt.SplitMultiUnitLines(NextNo);

        Page.Run(Page::"Custom GRN Card", GRNHeader);
    end;

    var
        StoreGRNLineSplitMgt: Codeunit "Store GRN Line Split Mgt.";
}
