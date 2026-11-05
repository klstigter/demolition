codeunit 60034 "Job Jnl Post Skill Runner"
{
    // Test runner with isolation DISABLED: data created/posted by codeunit 60032 is really
    // committed and stays in the database. Use this runner in the Test Tool (page 130401)
    // to run codeunit 60032 when you want to inspect the data afterwards.
    Subtype = TestRunner;
    TestIsolation = Disabled;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Job Jnl Post Skill Fields Test");
    end;
}
