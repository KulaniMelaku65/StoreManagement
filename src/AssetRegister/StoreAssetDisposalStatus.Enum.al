enum 60136 "Store Asset Disposal Status"
{
    Extensible = true;

    value(0; None)
    {
        Caption = ' ';
    }
    value(1; PendingApproval)
    {
        Caption = 'Pending Approval';
    }
    value(2; Approved)
    {
        Caption = 'Approved - Disposed';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
}
