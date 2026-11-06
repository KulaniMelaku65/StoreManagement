codeunit 60156 "Store GRN Line Split Mgt."
{
    // Fanisi's own GRN generation (both from a Purchase Order and from a Posted
    // Purchase Invoice) creates one GRN line per Purchase Line regardless of
    // quantity. This splits any Fixed Asset or Item line with more than one unit
    // into one line per unit right when the GRN is generated, so the store
    // keeper can fill in per-unit details (Category, and for Fixed Assets, Type/
    // Model/Serial No.) before confirming. Unit Cost is already a per-unit value
    // so it's simply copied to every split line; Line Amount (Unit Cost x 1)
    // works out the same as dividing the original total across the units.
    Permissions = tabledata "Custom GRN Lines" = RIM;

    procedure SplitMultiUnitLines(DocumentNo: Code[20])
    var
        GRNLine: Record "Custom GRN Lines";
    begin
        // One plain SetRange per type, rather than a combined '%1|%2' filter that
        // formats both enum values into text.
        GRNLine.Type := GRNLine.Type::"Fixed Asset";
        SplitLinesOfType(DocumentNo, GRNLine.Type);
        GRNLine.Type := GRNLine.Type::Item;
        SplitLinesOfType(DocumentNo, GRNLine.Type);
    end;

    local procedure SplitLinesOfType(DocumentNo: Code[20]; LineType: Enum "Purchase Line Type")
    var
        GRNLine: Record "Custom GRN Lines";
        UnitsToAdd: Integer;
    begin
        GRNLine.SetRange("Document No.", DocumentNo);
        GRNLine.SetRange(Type, LineType);
        GRNLine.SetFilter("Quantity To Receive", '>1');
        if GRNLine.FindSet(true) then
            repeat
                // A fractional quantity can't be split into whole units - leave it
                // as-is rather than guessing (mainly relevant for Items sold by
                // weight/volume, e.g. liters of liquid soap).
                if GRNLine."Quantity To Receive" = Round(GRNLine."Quantity To Receive", 1) then begin
                    UnitsToAdd := Round(GRNLine."Quantity To Receive", 1) - 1;
                    CreateSplitLines(GRNLine, UnitsToAdd);
                    GRNLine."Quantity Ordered" := 1;
                    GRNLine."Quantity To Receive" := 1;
                    GRNLine."Line Amount" := GRNLine."Unit Cost";
                    GRNLine."Line Amount Incl. VAT" := Round(GRNLine."Unit Cost Incl. VAT", 0.01);
                    GRNLine.Modify(false);
                end;
            until GRNLine.Next() = 0;
    end;

    local procedure CreateSplitLines(OriginalLine: Record "Custom GRN Lines"; UnitsToAdd: Integer)
    var
        NewLine: Record "Custom GRN Lines";
        NextLineNo: Integer;
        i: Integer;
    begin
        NextLineNo := LastLineNoFor(OriginalLine."Document No.");
        for i := 1 to UnitsToAdd do begin
            Clear(NewLine);
            NewLine."Type" := OriginalLine."Type";
            NewLine."No." := OriginalLine."No.";
            NewLine."Document No." := OriginalLine."Document No.";
            NewLine.Description := OriginalLine.Description;
            NewLine.Model := OriginalLine.Model;
            NewLine."Unit Of Measure" := OriginalLine."Unit Of Measure";
            NewLine."Location Code" := OriginalLine."Location Code";
            NewLine."Quantity Ordered" := 1;
            NewLine."Quantity To Receive" := 1;
            NewLine."Unit Cost" := OriginalLine."Unit Cost";
            NewLine."Line Amount" := OriginalLine."Unit Cost";
            NewLine."Unit Cost Incl. VAT" := OriginalLine."Unit Cost Incl. VAT";
            NewLine."Line Amount Incl. VAT" := Round(OriginalLine."Unit Cost Incl. VAT", 0.01);
            NewLine."Document Date" := OriginalLine."Document Date";
            NextLineNo += 1;
            NewLine."Line No" := NextLineNo;
            NewLine.Insert(false);
        end;
    end;

    local procedure LastLineNoFor(DocumentNo: Code[20]): Integer
    var
        GRNLine: Record "Custom GRN Lines";
    begin
        GRNLine.SetRange("Document No.", DocumentNo);
        GRNLine.SetCurrentKey("Line No");
        GRNLine.SetAscending("Line No", false);
        if GRNLine.FindFirst() then
            exit(GRNLine."Line No");
        exit(0);
    end;
}
