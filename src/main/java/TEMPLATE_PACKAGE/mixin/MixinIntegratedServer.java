package TEMPLATE_PACKAGE.mixin;

import net.minecraft.server.integrated.IntegratedServer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(IntegratedServer.class)
public class MixinIntegratedServer {
	// "Is Modded" section in crash report
	@Redirect(method = "method_4815", at = @At(
		value = "INVOKE",
		target = "Ljava/lang/Class;getSigners()[Ljava/lang/Object;"
	))
	private Object[] debrand$getSigners(Class<?> instance) {
		return new Object[] {};
	}
}
