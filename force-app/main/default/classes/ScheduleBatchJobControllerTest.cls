/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) Cpagemini.
* @What  : ScheduleBatchJobController.
* @Why   : This is Test class for ScheduleBatchJobController Class.
* @When  : 20- July -2021.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                         Modification ID         Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid  				    20 July-2021				Work ID / Case ID       Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid  				   20 July-2021			        Update                  Updated.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class ScheduleBatchJobControllerTest {

    
    
    
    @isTest
    public static void testMethodOne(){
        
        ScheduleBatchJobController sBJCObj = new ScheduleBatchJobController();
        sBJCObj.getPeriodMinutes();
        sBJCObj.getperiodHours();
        sBJCObj.hours = 2;
        sBJCObj.minutes = 15;
        Test.startTest();
        sBJCObj.scheduleBatchJob();
        sBJCObj.hours = 1;
        sBJCObj.minutes = 15;
        sBJCObj.scheduleBatchJob();
        sBJCObj.hours = null;
        sBJCObj.minutes = null;
        sBJCObj.scheduleBatchJob();
        Test.stopTest();
    }
    
        @isTest
    public static void testMethodSecond(){
        
        ScheduleBatchJobController sBJCObj = new ScheduleBatchJobController();
        sBJCObj.getPeriodMinutes();
        sBJCObj.getperiodHours();
        Test.startTest();
        sBJCObj.scheduleBatchJob();
        Test.stopTest();
    }
    

}