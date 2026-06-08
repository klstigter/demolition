Optimized Dynamic Planning   
Daily Short-Term Planning Driven by Progress, Capacity, and Constraints   
  
_Business process description and calculation concept_   
  
**Purpose: ** describe the daily planning process, the role of Job Tasks, Day Task Patterns, Day Tasks, Capacity Lines and Proposal Buffers, and the decision principles used by the planning engine.   
  
  
  
# 1\. Purpose of the Planning Process   
Optimized Dynamic Planning is designed for highly dynamic short-term work where daily changes are normal. The process continuously balances released work, available capacity, progress, and planning constraints. The first goal is to calculate the requested Day Task constellation for the next day. Assignment of actual resources is a next phase after the request calculation has been reviewed and accepted.   
The process is not meant to replace the planner. It creates explainable proposals. The planner remains in control and can accept or reject proposed changes.   
# 2\. Business Context   
* Most Job Tasks are planned as soon as possible, but they can still have hard or soft constraints.   
* Planning has a short time span and changes frequently, often from one day to the next.   
* The company wants to avoid unused internal capacity and unnecessary idle fixed pool capacity.   
* Flexible pool capacity can be requested when needed, but it is not guaranteed until confirmed by the vendor.   
* The system must avoid unnecessary planning noise and frequent small changes, especially when teams are already dispatched.   
* The proposal for actual Day Task request changes is always focused on the next day.   
# 3\. Main Objects in the Process   
|  **Object** <br>|  **Business role** <br>|
|----------|----------|
|  **Job Task** <br>|  **The operational work package. It stores release status, start date, end date, and planning constraints.** <br>|
|  **Day Task Pattern** <br>|  **The rule or pattern that defines how daily request lines are created or adjusted for a specific part of the Job Task.** <br>|
|  **Day Task** <br>|  **The daily request line. It stores requested time/capacity and later also contains assignment fields prefixed with Assigned.** <br>|
|  **Planning Change Log** <br>|  **The log that records progress, start-date changes, and end-date changes. A change in any of these fields can trigger recalculation.** <br>|
|  **Capacity Line** <br>|  **A time-based capacity snapshot. It can represent normal capacity, absence, holidays, overtime preference, and capacity hardness.** <br>|
|  **Proposal Buffer** <br>|  **The review area where old and proposed new values are shown. The planner accepts or rejects each proposal.** <br>|
  
  
# 4\. Request Calculation Before Assignment   
The first planning step is to calculate requests, not assignments. The Day Task line contains assignment fields, but these fields are handled in a later phase. The request calculation answers questions such as: how much work is needed tomorrow, which Job Tasks should receive request lines, and whether a request should be increased, reduced, moved, stretched, or removed.   
After the request constellation has been proposed and accepted, the assignment step can assign concrete internal resources, named fixed pool resources, or other confirmed capacity to the requested Day Task lines.   
# 5\. Planning Change Log and Recalculation Triggers   
The log table does not only save changes in progress. It also logs changes to the Job Task start date and end date. A change in any of these three fields can activate the recalculation procedure.   
|  **Logged value** <br>|  **Why it matters** <br>|
|----------|----------|
|  **Progress** <br>|  **Changes the forecast of remaining work. For example, if 40% of the houses are finished but 50% of the estimated hours are already used, the remaining work forecast must be adjusted.** <br>|
|  **Start Date** <br>|  **Changes the period in which the Job Task may begin and can influence whether Day Task requests should move.** <br>|
|  **End Date** <br>|  **Changes the available or allowed period and can influence stretching, narrowing, or capacity increase decisions.** <br>|
  
  
# 6\. Capacity Types and Priority   
When capacity is needed, the process follows a clear priority:   
1. Internal resources have the highest priority.   
2. Fixed pool resources have the next priority. These are committed or named external resources that the company is expected to use.   
3. Flexible pool resources are considered only when extra capacity is needed. This capacity is optional and not guaranteed. When the system proposes flexible pool capacity, the planner or company may first need to request this capacity from the vendor. Only after confirmation can it be treated as reliable capacity.   
Capacity Lines are time-based snapshots. They can represent normal capacity, absence, holidays, overtime preference, and the hardness of capacity. Hardness tells the planning engine whether capacity must be used, may be used, or must first be requested. The hardness value is copied from the resource or resource-pool setup when the Capacity Lines are created. Because the setup can change over time, hardness can vary over time.   
|  **Capacity hardness** <br>|  **Meaning** <br>|
|----------|----------|
|  **Fixed** <br>|  **Capacity that the system should use. This is typically internal capacity or committed fixed pool capacity.** <br>|
|  **Flexible** <br>|  **Capacity that may be used when needed. The company is free not to use it.** <br>|
|  **Possible** <br>|  **Capacity that must first be requested from the vendor and is not guaranteed until confirmed.** <br>|
  
  
# 7\. Job Task Constraints   
Job Task constraints determine how much freedom the planning engine has when it creates or changes Day Task requests. Constraints can be hard or soft. A hard constraint blocks the proposal when the rule is violated. A soft constraint may still allow a proposal, but the planner must be able to see that the proposal crosses or challenges the preferred boundary.   
|  **No.** <br>|  **Code** <br>|  **Meaning** <br>|  **Hardness** <br>|  **Example** <br>|
|----------|----------|----------|----------|----------|
|  **1** <br>|  **ASAP** <br>|  **As Soon As Possible** <br>|  **Hard/Soft** <br>|  **Normal default planning** <br>|
|  **2** <br>|  **ALAP** <br>|  **As Late As Possible** <br>|  **Hard/Soft** <br>|  **Delay until really needed** <br>|
|  **3** <br>|  **SNET** <br>|  **Start No Earlier Than** <br>|  **Hard/Soft** <br>|  **Technician unavailable before Monday** <br>|
|  **4** <br>|  **SNLT** <br>|  **Start No Later Than** <br>|  **Hard/Soft** <br>|  **Must start before permit expires** <br>|
|  **5** <br>|  **FNET** <br>|  **Finish No Earlier Than** <br>|  **Hard/Soft** <br>|  **Concrete drying time** <br>|
|  **6** <br>|  **FNLT** <br>|  **Finish No Later Than** <br>|  **Hard/Soft** <br>|  **Requested Delivery Date** <br>|
|  **7** <br>|  **MSO** <br>|  **Must Start On** <br>|  **Hard/Soft** <br>|  **Event starts exact day** <br>|
|  **8** <br>|  **MFO** <br>|  **Must Finish On** <br>|  **Hard/Soft** <br>|  **Government deadline exact date** <br>|
  
  
# 8\. Day Task Pattern   
A Day Task Pattern is bound to a Job Task and defines how Day Task request lines are created, increased, reduced, stretched, narrowed, or moved. The Job Task stores the constraints. The Day Task Pattern tells the system how the daily requests should behave within the freedom provided by those constraints.   
One Job Task can have multiple Day Task Patterns because the required occupation can change during the lifecycle of the Job Task. For example, a three-month Job Task may require two resources during the first four days, then ten resources per day in the main period, split into five fitters and five programmers, then four resources during the last two weeks, and finally one resource on the last day.   
The Day Task Pattern can have its own start and end definition or offset logic. It can also define whether the pattern follows working days or calendar days. Normally it follows working days. Each pattern should have its own behaviour, such as fixed length, stretch with the Job Task, keep near start, keep near end, or proportional behaviour.   
|  **Day Task Pattern concept** <br>|  **Explanation** <br>|
|----------|----------|
|  **Period / offset** <br>|  **Defines which part of the Job Task the pattern applies to. Offset logic can make the pattern move with the Job Task.** <br>|
|  **Capacity demand** <br>|  **Defines quantity, hours, skills, resource type, pool or other demand information.** <br>|
|  **Behaviour** <br>|  **Defines how the pattern reacts when the Job Task is stretched, narrowed, or moved.** <br>|
|  **Working day setting** <br>|  **Defines whether the pattern uses working days or calendar days. Normally this follows working days.** <br>|
|  **Fair policy fields** <br>|  **Can contain weights, reserve percentages, and thresholds used by the calculation model.** <br>|
  
  
  
  
  
# 9\. Horizons: Next Day, Five Weeks, and Beyond   
The process uses different horizons for different purposes. This distinction is critical.   
|  **Horizon** <br>|  **Purpose** <br>|
|----------|----------|
|  **Next day** <br>|  **The actual operational proposal for Day Task request changes. Proposal buffer records for Day Task requests are always for the next day.** <br>|
|  **First five weeks** <br>|  **The detailed analysis and recalculation horizon. Within this horizon, existing Day Task lines are considered the accurate source for daily requested work and capacity demand.** <br>|
|  **Beyond five weeks** <br>|  **Used only when needed for feasibility checks of a specific Job Task, especially stretching. After five weeks, the system should not rely on detailed Day Task lines as accurate daily data. It should use Job Task constraints and Day Task Patterns.** <br>|
  
  
The actual recalculation of Day Task request lines is limited to the first five weeks. However, the proposal generated for operational planning is only for the next day. The five-week view is used to calculate weighing factors and understand broader workload pressure. For stretching feasibility of a particular Job Task, the system may need to look further than five weeks, using the Job Task constraints and Day Task Patterns to understand whether stretching is possible.   
# 10\. Complete Planning Picture Before Factors   
The weighing factors may not be calculated from the current Job Task alone. The system must first build a complete planning picture across all relevant Job Tasks. Decisions such as stretching, narrowing, starting earlier, postponing, adding capacity, or reducing capacity depend on the total workload and capacity situation.   
Within the first five weeks, detailed Day Tasks provide the daily demand picture. After five weeks, the system relies on Day Task Patterns instead of detailed Day Tasks. Based on this complete picture, the engine calculates the factors that drive proposed actions in the Proposal Buffer.   
  
  
  
# 11\. Fair Planning Policy Model   
The recommended model is to first determine the allowed room, then apply the fair policy, then calculate a proposal factor, then apply the threshold, and finally create a proposal buffer record only when the result is meaningful.   
1. Determine the allowed room.   
2. Apply hard constraints.   
3. Apply the fair policy and planning reserve.   
4. Calculate the proposal factor.   
5. Check the threshold value.   
6. Create a proposal buffer record only when the proposed change is meaningful.   
This model should be used for stretching, narrowing, moving forward, postponing, increasing capacity, decreasing capacity, using flexible pool capacity, and team stability decisions. The model should be explainable. The planner should be able to understand why a proposal was created.   
  
  
  
# 12\. Threshold Logic for Next\-Day Proposals   
The system must not create a proposal for every technical difference. Small changes can create planning noise. Because operational proposals are always for the next day, the threshold check starts with the related Day Task for tomorrow.   
|  **Situation** <br>|  **Threshold behaviour** <br>|
|----------|----------|
|  **Day Task smaller than 8 hours** <br>|  **Changes are considered meaningful. This is already a small planning unit, so even a small change can matter.** <br>|
|  **Day Task of 8 hours or more** <br>|  **Normal threshold logic applies. Small changes should be suppressed when they are not meaningful compared with the daily workload, team size, pattern, or stability situation.** <br>|
  
  
Example: if a team of ten resources continues for three weeks, adding only eight hours total should not create a proposal. The change is too small compared with the remaining workload and would create unnecessary planning noise. But when the Day Task itself is smaller than eight hours, a smaller change can be meaningful and should not be suppressed by the same threshold logic.   
# 13\. Proposal Buffer   
The Proposal Buffer is the planner review screen. The system does not directly change the real planning when the calculation runs. It first writes the proposed changes to the buffer.   
|  **Proposal Buffer element** <br>|  **Meaning** <br>|
|----------|----------|
|  **Old value** <br>|  **The current planning situation.** <br>|
|  **New value** <br>|  **The proposed new situation.** <br>|
|  **Visual highlight** <br>|  **Changed values are shown clearly, for example with red font.** <br>|
|  **Suggested Action** <br>|  **The type of proposal, such as line added, line removed, date moved forward, date moved backward, capacity increased, or capacity decreased.** <br>|
|  **Planner Decision** <br>|  **The planner chooses Accept or Reject per proposal record.** <br>|
|  **Execution setting** <br>|  **The system can execute immediately after Accept/Reject or allow the planner to mark multiple decisions and process them later.** <br>|
  
  
The operational Proposal Buffer is focused on the next day. A separate function can be added, for example Update Day Task Pattern with This. This function can create a similar proposal for updating the Day Task Pattern when the planner sees that a next-day operational proposal should also influence future generation logic.   
# 14\. Typical Proposed Actions   
|  **Suggested Action** <br>|  **Business meaning** <br>|
|----------|----------|
|  **Add Day Task Line** <br>|  **Create an additional request line for tomorrow.** <br>|
|  **Remove Day Task Line** <br>|  **Remove a request line that is no longer needed for tomorrow.** <br>|
|  **Increase Requested Capacity** <br>|  **Increase hours, quantity, or request amount for tomorrow.** <br>|
|  **Decrease Requested Capacity** <br>|  **Decrease hours, quantity, or request amount for tomorrow.** <br>|
|  **Move Date Forward** <br>|  **Move relevant planning date earlier when allowed and useful.** <br>|
|  **Move Date Backward** <br>|  **Move relevant planning date later when allowed and fair.** <br>|
|  **Stretch Job Task** <br>|  **Spread work over a longer allowed period. The actual operational proposal remains next-day focused.** <br>|
|  **Narrow Job Task** <br>|  **Concentrate work into a shorter period when needed and allowed.** <br>|
|  **Update Day Task Pattern Proposal** <br>|  **Separate structural proposal to adjust the pattern behind future Day Task generation.** <br>|
  
  
# 15\. Business Decision Principles   
* Use internal resources before external capacity.   
* Use committed fixed pool resources before optional flexible pool resources.   
* Use flexible pool capacity only when extra capacity is needed and the vendor can confirm it.   
* Start released ASAP Job Tasks earlier when capacity would otherwise be unused, unless constraints block this.   
* Do not use all available flexibility immediately; keep planning reserve for future uncertainty.   
* Avoid frequent small changes to stable or dispatched teams.   
* Create proposals only when the change is meaningful for tomorrow.   
* Keep the planning decision explainable. The planner must understand the reason behind each proposal.   
# 16\. Short Technical Guidance for the Programmer   
The programmer should implement the calculation as a transparent rule-based factor model, not as a black-box vector or AI model. The system can use factor scores, but every score must come from understandable business rules and setup values.   
|  **Step** <br>|  **Technical meaning** <br>|
|----------|----------|
|  **Collect input** <br>|  **Read relevant Job Tasks, Day Task Patterns, Day Tasks, Capacity Lines and Planning Change Log entries.** <br>|
|  **Build picture** <br>|  **Build the full workload and capacity picture for the first five weeks. Use Day Task Patterns beyond five weeks only for specific feasibility checks.** <br>|
|  **Calculate factors** <br>|  **Calculate workload pressure, stretch possibility, capacity shortage, overcapacity, planning reserve, threshold and team stability factors.** <br>|
|  **Apply rules** <br>|  **Apply constraints, capacity priority, fair policy and threshold logic.** <br>|
|  **Create proposals** <br>|  **Write only meaningful next-day operational proposals to the Proposal Buffer.** <br>|
|  **Explain result** <br>|  **Store enough reason information so the planner can understand the proposal.** <br>|
  
  
# 17\. Summary   
Optimized Dynamic Planning creates a controlled daily planning process for short-term, dynamic work. The system uses progress, capacity, constraints, Day Task Patterns and fair planning rules to propose the next-day request constellation. The broader five-week view is used to calculate factors and understand pressure, but the operational proposal is always for tomorrow. The planner remains in control through the Proposal Buffer, where each proposed change can be accepted or rejected.   
