

var dinolightApp = angular.module('dinolightApp',[]);

dinolightApp.controller('dinoController',['$scope', '$interval', '$http',function($scope, $interval, $http){   
    var serverAddress = 'http://wjg9331.student.rit.edu:5000/c';
    $scope.powerToggle = function(){
        if($scope.mode == 'tv'){
            $scope.mode = 'off'        
        }
        else{
            $scope.mode = 'tv'
            $scope.program();
        }
        
        $http.post(serverAddress,  JSON.stringify({op:'set', what:'mode', to:$scope.mode})).
        success(function(data, status, headers, config){
            console.log(data);
            }).
        error(function(data, status, headers, config){
            console.log(data);
        });
    };
    $scope.power = false;
    
    $scope.tvGlowColor1 = '#0000ff';    
    $scope.tvGlowColor2 = '#0000ff';
    
    $scope.hueIP = "192.168.1.10";
    $scope.hueEnable = false;
    
    
    $interval(function(){
        //var currentColor = hsvToRgb(((new Date()).getTime() % 60000)/ 60000, 1, .75);
                         
        $scope.tvGlowColor1 = colorArrayToCode(hsvToRgb(((new Date()).getTime() % 60000)/60000, 1, 1)); 
        $scope.tvGlowColor2 = $scope.tvGlowColor1;
    }, 100);
    
    $http.post(serverAddress,  JSON.stringify({op:'get', what:'state'})).
    success(function(data, status, headers, config){
            console.log("success");
            console.log(data);
            $scope.mode = data.mode;
            $scope.hueEnable = data.hueEnable;
            $scope.hueIP = data.hueIP;
            $scope.vertLeds = data.vertLeds;
            $scope.horzLeds = data.horzLeds;
            }).
    error(function(data, status, headers, config){
        console.log(data);
    });
    
    $scope.program=function(){
        $http.post(serverAddress,  JSON.stringify({op:'set', what:'vertLeds', to:$scope.vertLeds})).
        success(function(data, status, headers, config){
            console.log(data);
            }).
        error(function(data, status, headers, config){
        console.log(data);
        });
        
        $http.post(serverAddress,  JSON.stringify({op:'set', what:'horzLeds', to:$scope.horzLeds})).
        success(function(data, status, headers, config){
            console.log(data);
            }).
        error(function(data, status, headers, config){
        console.log(data);
        });
        
        $http.post(serverAddress,  JSON.stringify({op:'updateCount'})).
        success(function(data, status, headers, config){
            console.log(data);
            }).
        error(function(data, status, headers, config){
        console.log(data);
        });
        
    };
    
    $scope.setServer=function(){
        $http.post(serverAddress,  JSON.stringify({op:'set', what:'hueEnable', to:$scope.hueEnable})).
        success(function(data, status, headers, config){
            console.log(data);
            }).
        error(function(data, status, headers, config){
        console.log(data);
        });
        
        $http.post(serverAddress,  JSON.stringify({op:'set', what:'hueIP', to:$scope.hueIP})).
        success(function(data, status, headers, config){
            console.log(data);
            }).
        error(function(data, status, headers, config){
        console.log(data);
        });
    };
}]);


function colorArrayToCode(currentColor){
    var red =  Math.round(currentColor[0]).toString(16);
    var green =  Math.round(currentColor[1]).toString(16);
    var blue =  Math.round(currentColor[2]).toString(16);
    
    if(red.length == 1){
        red = '0' + red;
    }   
    if(green.length == 1){
        green = '0' + green;
    }    
    if(blue.length == 1){
        blue = '0' + blue;
    }
    
    return '#'+ red + green + blue;

}

/**
 * Converts an HSV color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSV_color_space.
 * Assumes h, s, and v are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  v       The value
 * @return  Array           The RGB representation
 */
function hsvToRgb(h, s, v){
    var r, g, b;

    var i = Math.floor(h * 6);
    var f = h * 6 - i;
    var p = v * (1 - s);
    var q = v * (1 - f * s);
    var t = v * (1 - (1 - f) * s);

    switch(i % 6){
        case 0: r = v, g = t, b = p; break;
        case 1: r = q, g = v, b = p; break;
        case 2: r = p, g = v, b = t; break;
        case 3: r = p, g = q, b = v; break;
        case 4: r = t, g = p, b = v; break;
        case 5: r = v, g = p, b = q; break;
    }

    return [r * 255, g * 255, b * 255];
}

/**
 * Converts an RGB color value to HSL. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes r, g, and b are contained in the set [0, 255] and
 * returns h, s, and l in the set [0, 1].
 *
 * @param   {number}  r       The red color value
 * @param   {number}  g       The green color value
 * @param   {number}  b       The blue color value
 * @return  {Array}           The HSL representation
 */
function rgbToHsl(r, g, b){
    r /= 255, g /= 255, b /= 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b);
    var h, s, l = (max + min) / 2;

    if(max == min){
        h = s = 0; // achromatic
    }else{
        var d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch(max){
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }

    return [h, s, l];
}
