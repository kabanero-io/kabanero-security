/*
 * Copyright (c) 2019 IBM Corporation and others
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package kabasec;

import java.util.NoSuchElementException;

import org.eclipse.microprofile.config.ConfigProvider;

/**
 * allows github base url to be passed in through mp-config 
 * so private git repos can be used, example: https://github.mycompany.com
 *
 */
public class Config {
    private String gitHubApiUrlBase = null;
    
    
    public String getUserInfoUrl() {
       init();
       return gitHubApiUrlBase  + "/user";
    }
    public String getEmailUrl() {
       init();
       return gitHubApiUrlBase  + "/emails";
    }
    public String getTeamsUrl() {
       init();
       return gitHubApiUrlBase  + "/user/teams";
    }
    
    
    private void init() {
        if (gitHubApiUrlBase != null) {
            return;
        }
        org.eclipse.microprofile.config.Config mpConfig = ConfigProvider.getConfig();
        String key = null;
        try {
            key = mpConfig.getValue(Constants.GITHUB_URL_MPCONFIG_PROPERTYNAME, String.class);            
        } catch (NoSuchElementException e) {
            // it's not there
        }
        if (key == null || key.isEmpty()) {            
            key = Constants.GITHUB_API_URL_BASE;
        }
        gitHubApiUrlBase = key;
    }
    
}
