//
//  Shader.fsh
//  temp
//
//  Created by Lukas Valine on 4/2/17.
//  Copyright © 2017 Lukas Valine. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
