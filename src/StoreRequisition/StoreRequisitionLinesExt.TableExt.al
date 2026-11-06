tableextension 60144 "Store Requisition Lines Ext" extends "PROC-Store Requistion Lines"
{
    fields
    {
        // A line can still be started the old way (Type, then No.). The Asset or
        // Inventory Register details are filled in right after.
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                AutoFillTagNo();
                FillFromInventoryRegister();
            end;
        }

        // Changing the line type clears whichever register pick no longer applies,
        // so an Item line never keeps a Tag No. and an asset line never keeps an
        // Inventory Register entry.
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                if Type = Type::Item then
                    "Tag No." := '';
                if Type = Type::"Minor Asset" then
                    "Stock Entry No." := 0;
            end;
        }

        // Keep Line Amount in step when the requested quantity changes, for lines
        // whose Unit Cost came from a register.
        modify("Quantity Requested")
        {
            trigger OnAfterValidate()
            var
                InStore: Decimal;
            begin
                if Type = Type::"Minor Asset" then
                    if ("Tag No." <> '') and ("Quantity Requested" <> 1) then
                        Error(OneTaggedUnitErr);
                // Don't request more than the register holds.
                if (Type = Type::Item) and ("Stock Entry No." <> 0) then begin
                    InStore := RegisterQtyInStore();
                    if "Quantity Requested" > InStore then
                        Error(NotEnoughStockErr, InStore);
                end;
                if "Unit Cost" <> 0 then
                    "Line Amount" := Round("Unit Cost" * "Quantity Requested", 0.01);
            end;
        }

        // Pick a specific physical unit straight from the Asset Register. The
        // lookup lists every unit that is still Available; choosing one sets the
        // line to that unit's Fixed Asset (Type = Minor Asset) and fills in the
        // rest from the register row. OnValidate double-checks availability at
        // save time too, since two requisitions could otherwise both grab the same
        // tag before either is issued.
        field(60100; "Tag No."; Code[30])
        {
            Caption = 'Tag No.';
            // No TableRelation: Tag Number is not the primary key of the Asset
            // Register, and Business Central refuses a built-in link to a non-key
            // field when it validates or looks it up. The checks are done in code.

            trigger OnValidate()
            var
                AssetRegister: Record "Store Asset Register";
            begin
                if "Tag No." = '' then
                    exit;
                AssetRegister.SetRange("Tag No.", "Tag No.");
                if not AssetRegister.FindFirst() then
                    Error(TagNotFoundErr, "Tag No.");
                if AssetRegister."Availability Status" <> AssetRegister."Availability Status"::Available then
                    Error(TagNotAvailableErr, "Tag No.");
                Type := Type::"Minor Asset";
                // The Asset Register is the source of truth. If the unit is linked
                // to a Fixed Asset card, use its number; if not, the tag itself
                // identifies the line - no Fixed Asset is required.
                if AssetRegister."Fixed Asset No." <> '' then
                    "No." := AssetRegister."Fixed Asset No."
                else
                    "No." := CopyStr("Tag No.", 1, MaxStrLen("No."));
                "Stock Entry No." := 0;
                FillFromAssetRegister(AssetRegister);
            end;
        }

        // Pick stock straight from the Inventory Register. The lookup lists the
        // register rows; choosing one sets the line to that row's Item (Type =
        // Item) and fills in the rest from the register row.
        field(60101; "Stock Entry No."; Integer)
        {
            Caption = 'Inventory Register Entry';
            TableRelation = "Store Inventory Register"."Entry No.";

            trigger OnValidate()
            var
                InventoryRegister: Record "Store Inventory Register";
            begin
                if "Stock Entry No." = 0 then
                    exit;
                InventoryRegister.Get("Stock Entry No.");
                if InventoryRegister."Item No." = '' then
                    Error(NoItemErr, InventoryRegister.Description);
                Type := Type::Item;
                "No." := InventoryRegister."Item No.";
                "Tag No." := '';
                FillFromInventoryRow(InventoryRegister);
            end;
        }

        // Issuing Store used to point at FA Location. It now holds the Warehouse/
        // Location from the Asset or Inventory Register, so it points at Location.
        modify("Issuing Store")
        {
            TableRelation = Location;
        }
    }

    // What the stores' own registers say is available for this line:
    //   Minor Asset - 1 if the chosen Tag No. is still Available, else 0
    //   Item        - the Inventory Register quantity for this item (in the
    //                 line's Issuing Store, if one is set)
    // This replaces Fanisi's "Qty in store", which sums the standard Item
    // ledger (zero for assets and for stock that only lives on the register).
    procedure RegisterQtyInStore(): Decimal
    var
        AssetRegister: Record "Store Asset Register";
        InventoryRegister: Record "Store Inventory Register";
    begin
        case Type of
            Type::"Minor Asset":
                begin
                    if "Tag No." = '' then
                        exit(0);
                    AssetRegister.SetRange("Tag No.", "Tag No.");
                    AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
                    if AssetRegister.IsEmpty() then
                        exit(0);
                    exit(1);
                end;
            Type::Item:
                begin
                    if "No." = '' then
                        exit(0);
                    InventoryRegister.SetRange("Item No.", "No.");
                    if "Issuing Store" <> '' then
                        InventoryRegister.SetRange("Location Code", "Issuing Store");
                    InventoryRegister.CalcSums(Quantity);
                    exit(InventoryRegister.Quantity);
                end;
        end;
        exit(0);
    end;

    // When a Minor Asset line is entered the old way (by Fixed Asset No.), fill
    // in the Tag No. automatically if exactly one unit of that asset is still
    // Available. If there are several (e.g. 12 identical phones), leave it blank
    // so the Tag No. lookup is used to pick the specific unit.
    procedure AutoFillTagNo()
    var
        AssetRegister: Record "Store Asset Register";
    begin
        if (Type <> Type::"Minor Asset") or ("No." = '') or ("Tag No." <> '') then
            exit;
        AssetRegister.SetRange("Fixed Asset No.", "No.");
        AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
        if AssetRegister.Count() = 1 then begin
            AssetRegister.FindFirst();
            "Tag No." := AssetRegister."Tag No.";
            FillFromAssetRegister(AssetRegister);
        end;
    end;

    // Everything the Asset Register knows about the chosen unit goes onto the
    // line, so the requester and store keeper don't retype it.
    local procedure FillFromAssetRegister(var AssetRegister: Record "Store Asset Register")
    var
        LineDescription: Text;
    begin
        LineDescription := AssetRegister.Description;
        if AssetRegister.Model <> '' then
            LineDescription := LineDescription + ' ' + AssetRegister.Model;
        Description := CopyStr(DelChr(LineDescription, '<>'), 1, MaxStrLen(Description));
        "Issuing Store" := AssetRegister."Location Code";
        if AssetRegister."Unit of Measure Code" <> '' then
            "Unit of Measure" := CopyStr(AssetRegister."Unit of Measure Code", 1, MaxStrLen("Unit of Measure"));
        "Unit Cost" := AssetRegister."Unit Cost";
        // A tagged unit is exactly one physical item.
        if "Quantity Requested" = 0 then
            "Quantity Requested" := 1;
        if "Quantity To Issue" = 0 then
            "Quantity To Issue" := 1;
        "Line Amount" := Round("Unit Cost" * "Quantity Requested", 0.01);
    end;

    // For a regular stock Item line entered the old way (by Item No.), take the
    // details from the Inventory Register row that still holds this item - the
    // oldest one with stock, which is also the one issued from first.
    procedure FillFromInventoryRegister()
    var
        InventoryRegister: Record "Store Inventory Register";
    begin
        if (Type <> Type::Item) or ("No." = '') or ("Stock Entry No." <> 0) then
            exit;
        InventoryRegister.SetRange("Item No.", "No.");
        InventoryRegister.SetFilter(Quantity, '>0');
        if not InventoryRegister.FindFirst() then
            exit;
        "Stock Entry No." := InventoryRegister."Entry No.";
        FillFromInventoryRow(InventoryRegister);
    end;

    local procedure FillFromInventoryRow(var InventoryRegister: Record "Store Inventory Register")
    begin
        Description := CopyStr(InventoryRegister.Description, 1, MaxStrLen(Description));
        "Issuing Store" := InventoryRegister."Location Code";
        if InventoryRegister."Unit of Measure Code" <> '' then
            "Unit of Measure" := CopyStr(InventoryRegister."Unit of Measure Code", 1, MaxStrLen("Unit of Measure"));
        "Unit Cost" := InventoryRegister."Unit Cost";
        "Line Amount" := Round("Unit Cost" * "Quantity Requested", 0.01);
    end;

    var
        TagNotFoundErr: Label 'Tag No. %1 was not found on the Asset Register.', Comment = '%1 = tag number';
        TagNotAvailableErr: Label 'Tag No. %1 is not currently available - it may already be issued or disposed.', Comment = '%1 = tag number';
        OneTaggedUnitErr: Label 'A tagged asset is exactly one unit, so the quantity must be 1. To request more units, add a line for each tag.';
        NotEnoughStockErr: Label 'Only %1 in store according to the Inventory Register. Please request that amount or less.', Comment = '%1 = quantity available';
        NoItemErr: Label 'The Inventory Register row "%1" is not linked to an Item card yet, so it cannot be requested. Ask Finance to link it first.', Comment = '%1 = register description';
}
