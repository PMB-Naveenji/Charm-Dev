/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDValidatedReportsControllerTest.
* @Why   : ADDValidatedReportsControllerTest class for the ADDValidatedReportsController class.
* @When  : 15-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                15-DEC-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                28-APR-2020            Defect #79                    Modified.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                18-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class ADDValidatedReportsControllerTest {
    /*
    * @Method       : testADDValidatedReports.
    * @Description  : To test the ADDValidatedReportsController class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest(SeeAllData=true)
    public static void testADDValidatedReports() {

        Test.startTest();
        ADDValidatedReportsController validatedReportsPageCtrl = new ADDValidatedReportsController ();
        Integer pacReportsCount = [SELECT COUNT() FROM Report WHERE FolderName = 'Validated Report'];
        System.assertEquals(pacReportsCount, validatedReportsPageCtrl.PaCReportsIds.size());
        for (Report validatedReport : [SELECT Id, Name FROM Report WHERE Id IN :validatedReportsPageCtrl.PaCReportsIds ORDER BY NAME]){
            if (validatedReport.Name.startsWith('VR')) {
                validatedReportsPageCtrl.SelectedReportId = validatedReport.Id;
                break;
            }
        }
        validatedReportsPageCtrl.GenerateReportFiltersList();
        ADDValidatedReportsController.SelectedReportFilter srf;
        if (validatedReportsPageCtrl.SelectedReportFilters.size() > 0) {
            Boolean isRangeAdded = false;
            for (ADDValidatedReportsController.SelectedReportFilter pacFilter: validatedReportsPageCtrl.SelectedReportFilters) {
                if (pacFilter.FieldType.contains('date')) {
                    if (!isRangeAdded) {
                        pacFilter.Operator = 'range';
                        pacFilter.DateFromValue = '5/20/2017';
                        pacFilter.DateToValue = '5/20/2019';
                        isRangeAdded = true;
                    } else {
                        pacFilter.Operator = 'lt';
                        pacFilter.DateValue = '5/20/2019';
                    }
                } else if (pacFilter.FieldType == 'string') {
                    pacFilter.Operator = 'eq';
                    pacFilter.TextValue = '123Text';
                } else if (pacFilter.FieldType == 'picklist') {
                    pacFilter.Operator = 'eq';
                    pacFilter.MultiValue = new List<String>{'Test'};
                }
            }
        }
        PageReference pacReportPR = validatedReportsPageCtrl.RunReport();
        System.assertEquals(false, pacReportPR.getUrl().contains('apex'));
        validatedReportsPageCtrl.SelectedReportId = validatedReportsPageCtrl.VFReportsAPINames[0];
        validatedReportsPageCtrl.GenerateReportFiltersList();
        if (validatedReportsPageCtrl.SelectedReportFilters.size() > 0) {
            validatedReportsPageCtrl.SelectedReportFilters[0].TextValue = '123Test';
            srf = validatedReportsPageCtrl.SelectedReportFilters[0];
            System.assertEquals('eq', srf.ConvertOperatorNameToAbbr('equals'));
            System.assertEquals('ne', srf.ConvertOperatorNameToAbbr('notequal'));
            System.assertEquals('lt', srf.ConvertOperatorNameToAbbr('lessthan'));
            System.assertEquals('gt', srf.ConvertOperatorNameToAbbr('greaterthan'));
            System.assertEquals('le', srf.ConvertOperatorNameToAbbr('lessorequal'));
            System.assertEquals('ge', srf.ConvertOperatorNameToAbbr('greaterorequal'));
            System.assertEquals('co', srf.ConvertOperatorNameToAbbr('contains'));
            System.assertEquals('nc', srf.ConvertOperatorNameToAbbr('notcontain'));
            System.assertEquals('sw', srf.ConvertOperatorNameToAbbr('startswith'));
            System.assertEquals('in', srf.ConvertOperatorNameToAbbr('includes'));
            System.assertEquals('ex', srf.ConvertOperatorNameToAbbr('excludes'));
        }
        pacReportPR = validatedReportsPageCtrl.RunReport();
        System.assertEquals(true, pacReportPR.getUrl().contains('123Test'));
        Test.stopTest();

    }

}