package TEMPLATE_PACKAGE.mixin;

import net.minecraft.client.MinecraftClient;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

@Mixin(MinecraftClient.class)
public class MixinMinecraftClient {
	// "Is Modded" section in crash report
	@Redirect(method = "method_1509", at = @At(
		value = "INVOKE",
		target = "Ljava/lang/Class;getSigners()[Ljava/lang/Object;"
	))
	private static Object[] debrand$getSigners(Class<?> instance) {
		return new Object[] {};
	}
}
