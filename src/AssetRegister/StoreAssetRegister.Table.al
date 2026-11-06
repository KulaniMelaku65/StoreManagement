table 60125 "Store Asset Register"
{
    Caption = 'Asset Register';
    DataClassification = CustomerContent;
    LookupPageId = "Store Asset Register List";
    DrillDownPageId = "Store Asset Register List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; Category; Code[10])
        {
            Caption = 'Asset Class';
            TableRelation = "Store Asset Category";

            trigger OnValidate()
            begin
                StoreAssetTagMgt.TryAutoGenerateTagNoOnEntry(Rec);
            end;
        }
        field(15; "Type"; Code[10])
        {
            Caption = 'Type';
            TableRelation = "Store Asset Type";

            trigger OnValidate()
            begin
                StoreAssetTagMgt.TryAutoGenerateTagNoOnEntry(Rec);
            end;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Warehouse/Location';
            TableRelation = Location;
        }
        field(31; "Zone Code"; Code[20])
        {
            Caption = 'Zone';
        }
        field(32; "Shelf No."; Text[20])
        {
            Caption = 'Shelf #';
        }
        field(40; "Tag No."; Code[30])
        {
            Caption = 'Tag Number';

            trigger OnValidate()
            var
                AssetRegister: Record "Store Asset Register";
                FixedAsset: Record "Fixed Asset";
            begin
                if "Tag No." = '' then
                    exit;
                AssetRegister.SetRange("Tag No.", "Tag No.");
                AssetRegister.SetFilter("Entry No.", '<>%1', "Entry No.");
                if not AssetRegister.IsEmpty() then
                    Error(TagInUseErr, "Tag No.");
                FixedAsset.SetRange("Tag No.", "Tag No.");
                if not FixedAsset.IsEmpty() then
                    Error(TagInUseErr, "Tag No.");
            end;
        }
        field(50; Model; Text[100])
        {
            Caption = 'Model';
        }
        field(60; "Serial No."; Text[50])
        {
            Caption = 'Serial Number';
        }
        field(70; "Unit of Measure Code"; Code[10])
        {
            Caption = 'UoM';
            TableRelation = "Unit of Measure";
        }
        field(80; "Physical Count"; Decimal)
        {
            Caption = 'Physical Count';
            MinValue = 0;
            DecimalPlaces = 0 : 5;
        }
        field(90; "Program Code"; Code[20])
        {
            Caption = 'Program';
        }
        field(100; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            MinValue = 0;
        }
        field(101; "Total Cost"; Decimal)
        {
            Caption = 'Total Cost';
            Editable = false;
        }
        field(110; Status; Enum "Store Asset Condition")
        {
            Caption = 'Status';
        }
        field(120; Remarks; Text[250])
        {
            Caption = 'Remarks';
        }
        field(130; "Fixed Asset No."; Code[20])
        {
            Caption = 'Fixed Asset No.';
            TableRelation = "Fixed Asset";
            Editable = false;
        }
        field(140; "Last Counted Date"; Date)
        {
            Caption = 'Last Counted Date';
        }

        // Acquisition - normally filled from the Posted Purchase Invoice/GRN that
        // brought the item in, rather than retyped.
        field(150; "PO No."; Code[20])
        {
            Caption = 'PO Number';
        }
        field(151; "Vendor No."; Code[20])
        {
            Caption = 'Vendor';
            TableRelation = Vendor;
        }
        field(152; "Procured Date"; Date)
        {
            Caption = 'Procured Date';
        }

        // Custody - current-state fields for the store keeper's own view. The
        // detailed, timestamped history of who held what stays on Employee Items;
        // these just mirror the latest state onto the register row.
        field(155; "Availability Status"; Enum "Store Asset Avail. Status")
        {
            Caption = 'Availability';
            Editable = false;
        }
        field(160; "Issued Date"; Date)
        {
            Caption = 'Issued Date';
        }
        field(161; "Assigned To"; Text[100])
        {
            Caption = 'Assigned To';
        }
        field(170; "Return Date"; Date)
        {
            Caption = 'Return Date';
        }
        field(171; "Return To"; Text[100])
        {
            Caption = 'Return To';
        }
        field(180; "Reassigned Date"; Date)
        {
            Caption = 'Reassigned Date';
        }
        field(181; "Reassigned To"; Text[100])
        {
            Caption = 'Reassigned To';
        }

        // Disposal - a deliberate exception to the "no approvals" rule: disposal
        // requires a separate Asset Disposal Approver to confirm before the asset
        // is considered actually disposed. See "Store Asset Disposal Mgt." codeunit.
        field(190; "Disposal Method"; Enum "Store Asset Disposal Method")
        {
            Caption = 'Disposal Method';
        }
        field(191; "Disposal Status"; Enum "Store Asset Disposal Status")
        {
            Caption = 'Disposal Status';
            Editable = false;
        }
        field(192; "Disposal Requested Date"; Date)
        {
            Caption = 'Disposal Requested Date';
            Editable = false;
        }
        field(193; "Disposal Date"; Date)
        {
            Caption = 'Disposal Date';
            Editable = false;
        }
        field(194; "Disposal Approved By"; Text[50])
        {
            Caption = 'Disposal Approved By';
            Editable = false;
        }
        field(195; "Disposal Approval Date"; Date)
        {
            Caption = 'Disposal Approval Date';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Cat; Category, "Location Code")
        {
        }
        key(TagNo; "Tag No.")
        {
        }
    }

    trigger OnModify()
    begin
        UpdateTotalCost();
    end;

    trigger OnInsert()
    begin
        StoreAssetTagMgt.TryAutoGenerateTagNo(Rec);
        UpdateTotalCost();
    end;

    local procedure UpdateTotalCost()
    begin
        "Total Cost" := Round("Physical Count" * "Unit Cost", 0.01);
    end;

    var
        StoreAssetTagMgt: Codeunit "Store Asset Tag Mgt.";
        TagInUseErr: Label 'Tag No. %1 is already used on another entry.', Comment = '%1 = tag number';
}
