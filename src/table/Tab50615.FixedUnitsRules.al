table 50615 "Fixed Units Rules"
{
    Caption = 'Fixed Units Rules';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Enum "Fixed Units Source Type")
        {
            Caption = 'Source Type';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if ("Source Type" = CONST(JobTask))
                "Job Task"."Job No."
            else
            "Work Order"."Work Order No.";

        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("No."))
            ;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(5; "Rule Type"; Enum "Fixed Units Rule")
        {
            Caption = 'Rule Type';

            trigger OnValidate()
            begin
                case "Rule Type" of
                    "Rule Type"::"Named Resource":
                        begin
                            "Skill Code" := '';
                        end;
                    "Rule Type"::Skill:
                        begin
                            "Resource No." := '';
                            "Resource Pool Code" := '';
                        end;
                    "Rule Type"::"Resource Pool":
                        begin
                            "Resource No." := '';
                            "Skill Code" := '';
                        end;
                    "Rule Type"::Foreman:
                        begin
                            "Is Foreman" := true;
                            "Skill Code" := '';
                        end;
                end;
            end;
        }
        field(8; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";

            trigger OnValidate()
            var
                errorMessage: Label 'Resource No. can only be filled when Rule Type is Named Resource or Foreman.';
            begin
                if "Resource No." <> '' then
                    if not (("Rule Type" = "Rule Type"::"Named Resource") or ("Rule Type" = "Rule Type"::Foreman)) then
                        Error(errorMessage);
            end;
        }
        field(9; "Skill Code"; Code[20])
        {
            Caption = 'Skill Code';
            TableRelation = "Skill Code";
        }

        field(11; "Resource Pool Code"; Code[20])
        {
            Caption = 'Resource Pool Code';
            TableRelation = "Resource"."No." where("Is Pool" = const(true));

            trigger OnValidate()
            begin
                if "Resource Pool Code" <> '' then
                    TestField("Rule Type", "Rule Type"::"Resource Pool");
            end;
        }
        field(12; "Is Foreman"; Boolean)
        {
            Caption = 'Is Foreman';
        }
        field(13; "Pool Quantity of Lines"; Integer)
        {
            Caption = 'Fixed Pool Quantity';
        }

        field(14; "Duration in Hours"; Decimal)
        {
            Caption = 'Quantity';
            MinValue = 0;

        }
        field(19; Description; Text[100])
        {
            Caption = 'Description';
        }

    }

    keys
    {
        key(Key1; "Source Type", "No.", "Job Task No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "No.")
        {
        }
        key(Key5; "Resource No.")
        {
        }
        key(Key6; "Skill Code")
        {
        }
        key(Key7; "Resource Pool Code")
        {
        }
    }

    trigger OnInsert()
    begin
        TestMandatoryFields();
        ValidateRuleTypeFields();
    end;

    trigger OnModify()
    begin
        TestMandatoryFields();
        ValidateRuleTypeFields();
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
    end;

    var
        MustBeGreaterThanZeroErr: Label '%1 must be greater than zero.';
        StartingDateAfterEndingDateErr: Label '%1 must not be after %2.';
        EndingDateBeforeStartingDateErr: Label '%1 must not be before %2.';

    local procedure TestMandatoryFields()
    begin
        TestField("No.");
        TestField("Line No.");
        //TODO: add other mandatory fields as needed, and consider making some of them conditionally mandatory based on the Rule Type
    end;

    local procedure ValidateRuleTypeFields()
    begin
        //TODO
        case "Rule Type" of
            "Rule Type"::"Named Resource":
                TestField("Resource No.");
            "Rule Type"::Skill:
                TestField("Skill Code");
            "Rule Type"::"Resource Pool":
                TestField("Resource Pool Code");
            "Rule Type"::Foreman:
                begin
                    TestField("Is Foreman");
                    TestField("Resource No.");
                end;
        end;

    end;
}