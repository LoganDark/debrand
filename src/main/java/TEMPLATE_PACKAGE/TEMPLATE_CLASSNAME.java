package TEMPLATE_PACKAGE;

import net.fabricmc.api.ModInitializer;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public final class TEMPLATE_CLASSNAME implements ModInitializer {
	private static final Logger LOGGER = LogManager.getLogger(TEMPLATE_CLASSNAME.class);
	public static final String MOD_ID = "TEMPLATE_MODID";

	@Override
	public void onInitialize() {
		LOGGER.info("Hello, World!");
	}
}
