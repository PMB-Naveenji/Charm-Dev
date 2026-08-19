/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : StopRecursion.
* @Why   : To stop the recursive trigger call for ADDS4RiskManagementTriggerHandler.
* @When  : 23-MAR-2017.
* @Where : From StopRecursion.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:  
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description 
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class StopRecursion{
    public static boolean flag=true;

    /*
    * @Method       : runonce.
    * @Description  : To stop the recursive trigger call.
    * @Invoke       : N/A.
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