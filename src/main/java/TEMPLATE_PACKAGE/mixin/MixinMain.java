package TEMPLATE_PACKAGE.mixin;

import net.minecraft.SharedConstants;
import net.minecraft.client.main.Main;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyArgs;
import org.spongepowered.asm.mixin.injection.invoke.arg.Args;

@Mixin(Main.class)
public class MixinMain {
	@ModifyArgs(method = "main", at = @At(
		value = "INVOKE",
		target = "Lnet/minecraft/client/RunArgs$Game;<init>(ZLjava/lang/String;Ljava/lang/String;ZZZZ)V"
	))
	private static void debrand$initGame(Args args) {
		args.set(1, SharedConstants.getGameVersion().comp_4024()); // version
		args.set(2, "release"); // versionType
	}
}
