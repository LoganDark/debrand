package TEMPLATE_PACKAGE.mixin;

import net.minecraft.server.MinecraftServer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(MinecraftServer.class)
public abstract class MixinMinecraftServer {
	@Inject(method = "getServerModName", at = @At("HEAD"), cancellable = true)
	private void debrand$getServerModName(CallbackInfoReturnable<String> cir) {
		cir.setReturnValue("vanilla");
	}
}
