enum 50620 "WO Item Price Sales Type"
{
    Extensible = true;
    Caption = 'Work Order Item Price Sales Type';

    value(0; Customer)
    {
        Caption = 'Customer';
    }
    value(1; "Customer Price Group")
    {
        Caption = 'Customer Price Group';
    }
    value(2; "All Customers")
    {
        Caption = 'All Customers';
    }
}
