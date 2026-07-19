package states.stages.compatibility;

import tjson.TJSON as Json;
import sys.io.File;

class StageVSlice extends BaseStage
{
    var stageJson:Dynamic;

    override function createPost(){
        var modPath:String = Paths.modFolders('data/stages/' + PlayState.curStage + '.json');
		stageJson = Json.parse(File.getContent(modPath));
        // stageJson.props.sort((a.zIndex, b.zIndex) -> a.zIndex - b.zIndex);
        stageJson.props.sort(function(a, b) {
           if(a.zIndex < b.zIndex) return -1;
           else if(a.zIndex > b.zIndex) return 1;
           else return 0;
        });

        for(i in 0...stageJson.props.length){
            var prop = stageJson.props[i];

            var sprite:FlxSprite = new FlxSprite(prop.position[0], prop.position[1]);

            switch(prop.animType){
                default:
                    sprite.loadGraphic(Paths.image(prop.assetPath, "shared"));
            }

            if(prop.scroll != null)
                sprite.scrollFactor.set(prop.scroll[0], prop.scroll[1]);

            if(prop.scale != null)
                sprite.scale.set(prop.scale[0], prop.scale[1]);

            if(prop.alpha != null)
                sprite.alpha = prop.alpha;

            if(prop.blend == 'add')
                sprite.blend = openfl.display.BlendMode.ADD;

            if(cast(prop.zIndex, Int) > stageJson.characters.gf.zIndex)
                add(sprite);
            else
                addBehindGF(sprite);
        }
    }
}