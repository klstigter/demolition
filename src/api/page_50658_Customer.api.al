page 50658 CustomersOpt
{
    PageType = API;
    Caption = 'Job API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'Customer';
    EntitySetName = 'Customers';
    SourceTable = "Customer";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(address; Rec.Address)
                {
                    Caption = 'Address';
                }
                field(address2; Rec."Address 2")
                {
                    Caption = 'Address 2';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(County; Rec.County)
                {
                    Caption = 'County';
                }
                field(postCode; Rec."Post Code")
                {
                    Caption = 'Postal Code';
                }
                field(countryRegionId; Rec."Country/Region Code")
                {
                    Caption = 'Country Region Code';
                }
                field(systemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                }
                field(systemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Modified At';
                }
            }
        }
    }
}