codeunit 60021 "Day Planning Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Day Planning Creation Tests");
        Codeunit.Run(Codeunit::"Create Invoice Tests"); // codeunit 60023
    end;

    trigger OnBeforeTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; Permissions: TestPermissions): Boolean
    begin
        exit(true);
    end;

    trigger OnAfterTestRun(CodeunitId: Integer; CodeunitName: Text; FunctionName: Text; Permissions: TestPermissions; IsSuccess: Boolean)
    begin
    end;
}
