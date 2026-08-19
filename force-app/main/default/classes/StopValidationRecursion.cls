/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : StopValidationRecursion.
* @Why   : To stop the recursive validation call for ADDS4RiskManagementTriggerHandler.
* @When  : 27-JAN-2020.
* @Where : From ADDS4RiskManagementTriggerHandler, StopRecursion classes.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                   27-JAN-2020             Defect #1696 (CHARM-1687)     Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020             Code Audit                    Updated Jira reference with reference from Defect Tracker.
*                                                                                   Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   09-JUL-2020             Code Audit                     Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class StopValidationRecursion{
    public static boolean flag=true;

    /*
    * @Method       : runonce.
    * @Description  : To avoid nested trigger loop.
    * @Invoke       : From ADDS4RiskManagementTriggerHandler, StopRecursion classes.
    * @Return       : Boolean.
    * @Params       : N/A.
    */
    public static Boolean runonce(){
        if(flag){
            flag=false;
        }
        else {
            return flag;
        }

        return true;
    }
}