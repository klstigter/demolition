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
                field(blocked; BlockedText)
                {
                    Caption = 'Blocked';

                    trigger OnValidate()
                    var
                        NewBlocked: Enum "Customer Blocked";
                    begin
                        if DelChr(BlockedText, '<>', ' ') = '' then
                            NewBlocked := NewBlocked::" "
                        else
                            Evaluate(NewBlocked, DelChr(BlockedText, '<>', ' '));
                        Rec.Validate(Blocked, NewBlocked);
                    end;
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

    var
        BlockedText: Text;

    trigger OnAfterGetRecord()
    begin
        // Blank enum member " " would be serialized as "_x0020_"; expose it as text instead.
        BlockedText := DelChr(Format(Rec.Blocked), '<>', ' ');
        /*
            /// <summary>
            /// Indicates that the customer is not blocked and all transactions are allowed.
            /// </summary>
            value(0; " ") { Caption = ' '; }
            /// <summary>
            /// Indicates that the customer is blocked from shipping transactions only.
            /// </summary>
            value(1; "Ship") { Caption = 'Ship'; }
            /// <summary>
            /// Indicates that the customer is blocked from invoicing transactions only.
            /// </summary>
            value(2; "Invoice") { Caption = 'Invoice'; }
            /// <summary>
            /// Indicates that the customer is blocked from all sales transactions.
            /// </summary>
            value(3; "All") { Caption = 'All'; }
        */
    end;
}