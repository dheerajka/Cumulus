/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Enum of valid Rollup Operation Types and supporting static methods for those Enums.
*/
public class CRLP_Operation {

    public enum RollupType {
        COUNT,
        SUM,
        AVERAGE,
        LARGEST,
        SMALLEST,
        FIRST,
        LAST,
        YEARS_DONATED,
        CURRENT_STREAK,
        BEST_YEAR,
        BEST_YEAR_TOTAL
    }

    public enum YearlyOperationType {
        ALL_TIME,
        YEARS_BACK,
        DAYS_AGO
    }

    /**
     * @description Converts the enum strings into friendly strings for the pick-lists. The Enum value
     * and the String label should exactly match the picklist values in the Rollup__mdt.Operation__c field
     */
    public static Map<CRLP_Operation.RollupType, String> getRollupOperationTypes() {
        return new Map<CRLP_Operation.RollupType, String>{
                CRLP_Operation.RollupType.COUNT => 'Count',
                CRLP_Operation.RollupType.SUM => 'Sum',
                CRLP_Operation.RollupType.AVERAGE => 'Average',
                CRLP_Operation.RollupType.LARGEST => 'Largest',
                CRLP_Operation.RollupType.SMALLEST => 'Smallest',
                CRLP_Operation.RollupType.FIRST => 'First',
                CRLP_Operation.RollupType.LAST => 'Last',
                CRLP_Operation.RollupType.YEARS_DONATED => 'Years Donated',
                CRLP_Operation.RollupType.CURRENT_STREAK => 'Current Streak',
                CRLP_Operation.RollupType.BEST_YEAR => 'Best Year',
                CRLP_Operation.RollupType.BEST_YEAR_TOTAL => 'Best Year Total'
        };
    }

    /**
     * @description Yearly Operations for YearsBack and DaysAgo are only supported for the Count, Sum,
     * Largest and Smallest rollup operations. All others support AllTime only.
     * @param CRLP_Operation.RollupType
     * @return List of valid SelectOptions to display
     */
    public static List<SelectOption> getAvailableYearlyOperationTypes(String rollupOperation) {
        List<SelectOption> options = new List<SelectOption>{
                new SelectOption(YearlyOperationType.ALL_TIME.name(), 'All Time')
        };
        if (rollupOperation == CRLP_Operation.RollupType.SUM.name() ||
                rollupOperation == CRLP_Operation.RollupType.COUNT.name() ||
                rollupOperation == CRLP_Operation.RollupType.LARGEST.name() ||
                rollupOperation == CRLP_Operation.RollupType.SMALLEST.name()) {
            options.add(new SelectOption(YearlyOperationType.YEARS_BACK.name(), 'Years Back'));
            options.add(new SelectOption(YearlyOperationType.DAYS_AGO.name(), 'Days Ago'));
        }
        return options;
    }

    /**
     * @description Converts the picklist value for RollupType into a CRLP_Operation.RollupType enum
     * @param operation name (CRLP_Operation.RollupType.name())
     * @return CRLP_Operation.RollupType enum
     */
    public static CRLP_Operation.RollupType getRollupTypeFromString(String operation) {
        for (CRLP_Operation.RollupType rt : getRollupOperationTypes().keySet()) {
            if (rt.name() == operation) {
                return rt;
            }
        }
        return null;
    }

    /**
     * @description Returns a list of Detail Field types that are valid for a given Rollup Operation
     * @param operation RollupType
     */
    public static List<SoapType> getAvailableFieldTypesForDetailField(CRLP_Operation.RollupType operation) {

        List<SoapType> types = new List<SoapType>();
        if (operation == CRLP_Operation.RollupType.LARGEST || operation == CRLP_Operation.RollupType.SMALLEST
                || operation == CRLP_Operation.RollupType.SUM || operation == CRLP_Operation.RollupType.AVERAGE
                || operation == CRLP_Operation.RollupType.BEST_YEAR_TOTAL) {

            // Sum, Average, Largest and Smallest only support numbers
            types.add(SoapType.DOUBLE);

        } else if (operation == CRLP_Operation.RollupType.FIRST || operation == CRLP_Operation.RollupType.LAST
                || operation == CRLP_Operation.RollupType.YEARS_DONATED || operation == CRLP_Operation.RollupType.BEST_YEAR) {

            // Sum, Average, Largest and Smallest only support numbers
            types.add(SoapType.DATE);
        } // Count and YearsDonated are special cases that do not require a field of any kind.

        return types;
    }
}