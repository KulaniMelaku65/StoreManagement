enum 60124 "Store Asset Condition"
{
    Extensible = true;
    Caption = 'Condition Status';

    value(0; Active) { Caption = 'A - Active / Usable'; }
    value(1; Damaged) { Caption = 'D - Damaged'; }
    value(2; Obsolete) { Caption = 'O - Obsolete'; }
    value(3; Expired) { Caption = 'E - Expired'; }
    value(4; RequiresRepair) { Caption = 'R - Requires Repair'; }
    value(5; Unidentified) { Caption = 'U - Unidentified / Not Registered'; }
}
